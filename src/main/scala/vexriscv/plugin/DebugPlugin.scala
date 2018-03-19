package vexriscv.plugin

import spinal.lib.com.jtag.Jtag
import spinal.lib.system.debugger.{JtagBridge, SystemDebugger, SystemDebuggerConfig}
import vexriscv.plugin.IntAluPlugin.{ALU_CTRL, AluCtrlEnum}
import vexriscv._
import vexriscv.ip._
import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba3.apb.{Apb3, Apb3Config}
import spinal.lib.bus.avalon.{AvalonMM, AvalonMMConfig}

import scala.collection.mutable.ArrayBuffer


case class DebugExtensionCmd() extends Bundle{
  val wr = Bool
  val address = UInt(8 bit)
  val data = Bits(32 bit)
}
case class DebugExtensionRsp() extends Bundle{
  val data = Bits(32 bit)
}

case class DebugExtensionBus() extends Bundle with IMasterSlave{
  val cmd = Stream(DebugExtensionCmd())
  val rsp = DebugExtensionRsp() //one cycle latency

  override def asMaster(): Unit = {
    master(cmd)
    in(rsp)
  }

  def fromApb3(): Apb3 ={
    val apb = Apb3(Apb3Config(
      addressWidth = 8,
      dataWidth = 32,
      useSlaveError = false
    ))

    cmd.valid := apb.PSEL(0) && apb.PENABLE
    cmd.wr := apb.PWRITE
    cmd.address := apb.PADDR
    cmd.data := apb.PWDATA

    apb.PREADY := cmd.ready
    apb.PRDATA := rsp.data

    apb
  }

  def fromAvalon(): AvalonMM ={
    val bus = AvalonMM(AvalonMMConfig.fixed(addressWidth = 8,dataWidth = 32, readLatency = 1))

    cmd.valid := bus.read || bus.write
    cmd.wr := bus.write
    cmd.address := bus.address
    cmd.data := bus.writeData

    bus.waitRequestn := cmd.ready
    bus.readData := rsp.data

    bus
  }

  def fromJtag(): Jtag ={
    val jtagConfig = SystemDebuggerConfig(
      memAddressWidth = 32,
      memDataWidth    = 32,
      remoteCmdWidth  = 1
    )
    val jtagBridge = new JtagBridge(jtagConfig)
    val debugger = new SystemDebugger(jtagConfig)
    debugger.io.remote <> jtagBridge.io.remote
    debugger.io.mem.cmd.valid           <> cmd.valid
    debugger.io.mem.cmd.ready           <> cmd.ready
    debugger.io.mem.cmd.wr              <> cmd.wr
    cmd.address := debugger.io.mem.cmd.address.resized
    debugger.io.mem.cmd.data            <> cmd.data
    debugger.io.mem.rsp.valid           <> RegNext(cmd.fire).init(False)
    debugger.io.mem.rsp.payload         <> rsp.data

    jtagBridge.io.jtag
  }
}

case class DebugExtensionIo() extends Bundle with IMasterSlave{
  val bus = DebugExtensionBus()
  val resetOut = Bool

  override def asMaster(): Unit = {
    master(bus)
    in(resetOut)
  }
}


//Allow to avoid instruction cache plugin to be confused by new instruction poping in the pipeline
trait InstructionInjector{
  def isInjecting(stage : Stage) : Bool
}

class DebugPlugin(val debugClockDomain : ClockDomain) extends Plugin[VexRiscv] with InstructionInjector {

  var io : DebugExtensionIo = null
  val injectionAsks = ArrayBuffer[(Stage, Bool)]()
  var isInjectingOnDecode : Bool = null
  override def isInjecting(stage: Stage) : Bool = if(stage == pipeline.decode) isInjectingOnDecode else False

  object IS_EBREAK extends Stageable(Bool)
  override def setup(pipeline: VexRiscv): Unit = {
    import Riscv._
    import pipeline.config._

    io = slave(DebugExtensionIo()).setName("debug")

    val decoderService = pipeline.service(classOf[DecoderService])

    decoderService.addDefault(IS_EBREAK, False)
    decoderService.add(EBREAK,List(
      IS_EBREAK -> True,
      SRC_USE_SUB_LESS -> False,
      SRC1_CTRL -> Src1CtrlEnum.RS, // Zero
      SRC2_CTRL -> Src2CtrlEnum.PC,
      ALU_CTRL  -> AluCtrlEnum.ADD_SUB //Used to get the PC value in busReadDataReg
    ))

    isInjectingOnDecode = Bool()
  }


  override def build(pipeline: VexRiscv): Unit = {
    import pipeline._
    import pipeline.config._

    val logic = debugClockDomain {pipeline plug new Area{
      val iBusFetcher = service(classOf[IBusFetcher])
      val insertDecodeInstruction = False
      val firstCycle = RegNext(False) setWhen (io.bus.cmd.ready)
      val secondCycle = RegNext(firstCycle)
      val resetIt = RegInit(False)
      val haltIt = RegInit(False)
      val stepIt = RegInit(False)

      val isPipActive = RegNext(List(decode,execute, memory, writeBack).map(_.arbitration.isValid).orR)
      val isPipBusy = isPipActive || RegNext(isPipActive)
      val haltedByBreak = RegInit(False)


      val busReadDataReg = Reg(Bits(32 bit))
      when(writeBack.arbitration.isValid) {
        busReadDataReg := writeBack.output(REGFILE_WRITE_DATA)
      }
      io.bus.cmd.ready := True
      io.bus.rsp.data := busReadDataReg
      when(!RegNext(io.bus.cmd.address(2))){
        io.bus.rsp.data(0) := resetIt
        io.bus.rsp.data(1) := haltIt
        io.bus.rsp.data(2) := isPipBusy
        io.bus.rsp.data(3) := haltedByBreak
        io.bus.rsp.data(4) := stepIt
      }

      when(io.bus.cmd.valid) {
        switch(io.bus.cmd.address(2 downto 2)) {
          is(0) {
            when(io.bus.cmd.wr) {
              stepIt := io.bus.cmd.data(4)
              resetIt setWhen (io.bus.cmd.data(16)) clearWhen (io.bus.cmd.data(24))
              haltIt setWhen (io.bus.cmd.data(17)) clearWhen (io.bus.cmd.data(25))
              haltedByBreak clearWhen (io.bus.cmd.data(25))
            }
          }
          is(1) {
            when(io.bus.cmd.wr) {
              insertDecodeInstruction := True
              decode.arbitration.isValid.getDrivingReg setWhen (firstCycle)
              decode.arbitration.haltItself setWhen (secondCycle)
              io.bus.cmd.ready := !firstCycle && !secondCycle && execute.arbitration.isValid
            }
          }
        }
      }

      Component.current.addPrePopTask(() => {
        //Check if the decode instruction is driven by a register
        val instructionDriver = try {decode.input(INSTRUCTION).getDrivingReg} catch { case _ : Throwable => null}
        if(instructionDriver != null){ //If yes =>
          //Insert the instruction by writing the "fetch to decode instruction register",
          // Work even if it need to cross some hierarchy (caches)
          instructionDriver.component.rework {
            when(insertDecodeInstruction.pull()) {
              instructionDriver := io.bus.cmd.data.pull()
            }
          }
        } else{
          //Insert the instruction via a mux in the decode stage
          when(RegNext(insertDecodeInstruction)){
            decode.input(INSTRUCTION) := RegNext(io.bus.cmd.data)
          }
        }
      })


      when(execute.arbitration.isFiring && execute.input(IS_EBREAK)) {
        decode.arbitration.haltByOther := True
        decode.arbitration.flushAll := True
        haltIt := True
        haltedByBreak := True
      }

      when(haltIt) {
        iBusFetcher.haltIt()
//        decode.arbitration.haltByOther := True
      }

      when(stepIt && decode.arbitration.isFiring) {
        haltIt := True
      }
      when(stepIt && Cat(pipeline.stages.map(_.arbitration.redoIt)).asBits.orR) {
        haltIt := False
      }
      io.resetOut := RegNext(resetIt)

      if(serviceExist(classOf[InterruptionInhibitor])) {
        when(haltIt || stepIt) {
          service(classOf[InterruptionInhibitor]).inhibateInterrupts()
        }
      }
      if(serviceExist(classOf[ExceptionInhibitor])) {
        when(haltIt) {
          service(classOf[ExceptionInhibitor]).inhibateException()
        }
      }
    }}


    isInjectingOnDecode := RegNext(logic.insertDecodeInstruction) init(False)
  }
}
