package vexriscv.plugin

import vexriscv._
import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba4.axi._
import spinal.lib.bus.avalon.{AvalonMM, AvalonMMConfig}



case class IBusSimpleCmd() extends Bundle{
  val pc = UInt(32 bits)
}

case class IBusSimpleRsp() extends Bundle with IMasterSlave{
  val error = Bool
  val inst  = Bits(32 bits)

  override def asMaster(): Unit = {
    out(error,inst)
  }
}



import StreamVexPimper._

object IBusSimpleBus{
  def getAxi4Config() = Axi4Config(
    addressWidth = 32,
    dataWidth = 32,
    useId = false,
    useRegion = false,
    useBurst = false,
    useLock = false,
    useQos = false,
    useLen = false,
    useResp = true,
    useSize = false
  )

  def getAvalonConfig() = AvalonMMConfig.pipelined(
    addressWidth = 32,
    dataWidth = 32
  ).getReadOnlyConfig.copy(
    useResponse = true,
    maximumPendingReadTransactions = 8
  )
}


case class IBusSimpleBus(interfaceKeepData : Boolean) extends Bundle with IMasterSlave {
  var cmd = Stream(IBusSimpleCmd())
  var rsp = Flow(IBusSimpleRsp())

  override def asMaster(): Unit = {
    master(cmd)
    slave(rsp)
  }


  def toAxi4ReadOnly(): Axi4ReadOnly = {
    assert(!interfaceKeepData)
    val axi = Axi4ReadOnly(IBusSimpleBus.getAxi4Config())

    axi.ar.valid := cmd.valid
    axi.ar.addr  := cmd.pc(axi.readCmd.addr.getWidth -1 downto 2) @@ U"00"
    axi.ar.prot  := "110"
    axi.ar.cache := "1111"
    cmd.ready := axi.ar.ready


    rsp.valid := axi.r.valid
    rsp.inst := axi.r.data
    rsp.error := !axi.r.isOKAY()
    axi.r.ready := True


    //TODO remove
    val axi2 = Axi4ReadOnly(IBusSimpleBus.getAxi4Config())
    axi.ar >-> axi2.ar
    axi.r << axi2.r
//    axi2 << axi
    axi2
  }

  def toAvalon(): AvalonMM = {
    assert(!interfaceKeepData)
    val avalonConfig = IBusSimpleBus.getAvalonConfig()
    val mm = AvalonMM(avalonConfig)

    mm.read := cmd.valid
    mm.address := (cmd.pc >> 2) @@ U"00"
    cmd.ready := mm.waitRequestn

    rsp.valid := mm.readDataValid
    rsp.inst := mm.readData
    rsp.error := mm.response =/= AvalonMM.Response.OKAY

    mm
  }
}





class IBusSimplePlugin(interfaceKeepData : Boolean, catchAccessFault : Boolean, pendingMax : Int = 7) extends IBusFetcherImpl(
    catchAccessFault = catchAccessFault,
    resetVector = BigInt(0x80000000l),
    keepPcPlus4 = false,
    decodePcGen = false,
    compressedGen = false,
    cmdToRspStageCount = 1,
    rspStageGen = false,
    injectorReadyCutGen = false,
    relaxedPcCalculation = false,
    prediction = NONE,
    catchAddressMisaligned = true,
    injectorStage = true){
  var iBus : IBusSimpleBus = null

  override def setup(pipeline: VexRiscv): Unit = {
    super.setup(pipeline)
    iBus = master(IBusSimpleBus(interfaceKeepData)).setName("iBus")
  }

  override def build(pipeline: VexRiscv): Unit = {
    import pipeline._
    import pipeline.config._

    pipeline plug new FetchArea(pipeline) {

      val cmd = new Area {
        def input = fetchPc.output
        def output = iBusRsp.input

        output << input.continueWhen(iBus.cmd.fire)

        //Avoid sending to many iBus cmd
        val pendingCmd = Reg(UInt(log2Up(pendingMax + 1) bits)) init (0)
        val pendingCmdNext = pendingCmd + iBus.cmd.fire.asUInt - iBus.rsp.fire.asUInt
        pendingCmd := pendingCmdNext

        iBus.cmd.valid := input.valid && output.ready && pendingCmd =/= pendingMax
        iBus.cmd.pc := input.payload(31 downto 2) @@ "00"
      }


      val rsp = new Area {
        import iBusRsp._
        //Manage flush for iBus transactions in flight
        val discardCounter = Reg(UInt(log2Up(pendingMax + 1) bits)) init (0)
        discardCounter := discardCounter - (iBus.rsp.fire && discardCounter =/= 0).asUInt
        when(flush) {
          discardCounter := (if(relaxedPcCalculation) cmd.pendingCmdNext else cmd.pendingCmd - iBus.rsp.fire.asUInt)
        }


//        val rsp = recursive[Stream[IBusSimpleRsp]](rspUnbuffered, cmdToRspStageCount, x => x.s2mPipe(flush))
        val rspBuffer = StreamFifoLowLatency(IBusSimpleRsp(), cmdToRspStageCount)
        rspBuffer.io.push << iBus.rsp.throwWhen(discardCounter =/= 0).toStream
        rspBuffer.io.flush := flush

        val fetchRsp = FetchRsp()
        fetchRsp.pc := inputPipeline.last.payload
        fetchRsp.rsp := rspBuffer.io.pop.payload
        fetchRsp.rsp.error.clearWhen(!rspBuffer.io.pop.valid) //Avoid interference with instruction injection from the debug plugin


        val join = StreamJoin(Seq(inputPipeline.last, rspBuffer.io.pop), fetchRsp)
        inputPipeline.last.ready setWhen(!inputPipeline.last.valid)
        output << (if(rspStageGen) join.m2sPipeWithFlush(flush) else join)
      }
    }
  }
}