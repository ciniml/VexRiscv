package vexriscv.plugin

import vexriscv._
import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba4.axi._
import spinal.lib.bus.avalon.{AvalonMM, AvalonMMConfig}
import vexriscv.Riscv.IMM

import scala.collection.mutable.ArrayBuffer


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



class IBusSimplePlugin(interfaceKeepData : Boolean, catchAccessFault : Boolean, pendingMax : Int = 7) extends Plugin[VexRiscv] with JumpService with IBusFetcher{
  var iBus : IBusSimpleBus = null
  var prefetchExceptionPort : Flow[ExceptionCause] = null
  def resetVector = BigInt(0x80000000l)
  def keepPcPlus4 = false
  def decodePcGen = false
  def compressedGen = false
  def cmdToRspStageCount = 1
  def rspStageGen = false
  def injectorReadyCutGen = false
  def relaxedPcCalculation = false
  def prediction : BranchPrediction = STATIC
  var decodePrediction : DecodePredictionBus = null
  assert(cmdToRspStageCount >= 1)
  assert(!(compressedGen && !decodePcGen))
  lazy val fetcherHalt = False
  lazy val decodeNextPcValid = Bool
  lazy val decodeNextPc = UInt(32 bits)
  def nextPc() = (decodeNextPcValid, decodeNextPc)

  var predictionJumpInterface : Flow[UInt] = null

  override def haltIt(): Unit = fetcherHalt := True

  case class JumpInfo(interface :  Flow[UInt], stage: Stage, priority : Int)
  val jumpInfos = ArrayBuffer[JumpInfo]()
  override def createJumpInterface(stage: Stage, priority : Int = 0): Flow[UInt] = {
    val interface = Flow(UInt(32 bits))
    jumpInfos += JumpInfo(interface,stage, priority)
    interface
  }


  var decodeExceptionPort : Flow[ExceptionCause] = null
  override def setup(pipeline: VexRiscv): Unit = {
    iBus = master(IBusSimpleBus(interfaceKeepData)).setName("iBus")
    if(catchAccessFault) {
      val exceptionService = pipeline.service(classOf[ExceptionService])
      decodeExceptionPort = exceptionService.newExceptionPort(pipeline.decode,1).setName("iBusErrorExceptionnPort")
    }

    pipeline(RVC_GEN) = compressedGen

    prediction match {
      case NONE =>
      case STATIC | DYNAMIC => {
        predictionJumpInterface = createJumpInterface(pipeline.decode)
        decodePrediction = pipeline.service(classOf[PredictionInterface]).askDecodePrediction()
      }
    }
  }

  override def build(pipeline: VexRiscv): Unit = {
    import pipeline._
    import pipeline.config._

    pipeline plug new Area {

      //JumpService hardware implementation
      val jump = new Area {
        val sortedByStage = jumpInfos.sortWith((a, b) => {
          (pipeline.indexOf(a.stage) > pipeline.indexOf(b.stage)) ||
            (pipeline.indexOf(a.stage) == pipeline.indexOf(b.stage) && a.priority > b.priority)
        })
        val valids = sortedByStage.map(_.interface.valid)
        val pcs = sortedByStage.map(_.interface.payload)

        val pcLoad = Flow(UInt(32 bits))
        pcLoad.valid := jumpInfos.map(_.interface.valid).orR
        pcLoad.payload := MuxOH(OHMasking.first(valids.asBits), pcs)
      }


      def flush = jump.pcLoad.valid

      class PcFetch extends Area{
        val output = Stream(UInt(32 bits))
      }

      val fetchPc = if(relaxedPcCalculation) new PcFetch {
        //PC calculation without Jump
        val pcReg = Reg(UInt(32 bits)) init (resetVector) addAttribute (Verilator.public)
        val pcPlus4 = pcReg + 4
        if (keepPcPlus4) KeepAttribute(pcPlus4)
        when(output.fire) {
          pcReg := pcPlus4
        }

        //Realign
        if(compressedGen){
          when(output.fire){
            pcReg(1 downto 0) := 0
          }
        }

        //application of the selected jump request
        when(jump.pcLoad.valid) {
          pcReg := jump.pcLoad.payload
        }

        output.valid := RegNext(True) init (False) // && !jump.pcLoad.valid
        output.payload := pcReg
      } else new PcFetch{
        //PC calculation without Jump
        val pcReg = Reg(UInt(32 bits)) init(resetVector) addAttribute(Verilator.public)
        val inc = RegInit(False)

        val pc = pcReg + (inc ## B"00").asUInt
        val samplePcNext = False

        when(jump.pcLoad.valid) {
          inc := False
          samplePcNext := True
          pc := jump.pcLoad.payload
        }


        when(output.fire){
          inc := True
          samplePcNext := True
        }


        when(samplePcNext) {
          pcReg := pc
        }

        if(compressedGen) {
          when(output.fire) {
            pcReg(1 downto 0) := 0
            when(pc(1)){
              inc := True
            }
          }
        }

        output.valid := RegNext(True) init (False)
        output.payload := pc
      }

      val decodePc = ifGen(decodePcGen)(new Area {
        //PC calculation without Jump
        val pcReg = Reg(UInt(32 bits)) init (resetVector) addAttribute (Verilator.public)
        val pcPlus = if(compressedGen)
          pcReg + ((decode.input(IS_RVC)) ? U(2) | U(4))
        else
          pcReg + 4

        if (keepPcPlus4) KeepAttribute(pcPlus)
        when(decode.arbitration.isFiring) {
          pcReg := pcPlus
        }

        //application of the selected jump request
        when(jump.pcLoad.valid) {
          pcReg := jump.pcLoad.payload
        }
      })


      val iBusCmd = new Area {
        def input = fetchPc.output

        val output = input.continueWhen(iBus.cmd.fire)

        //Avoid sending to many iBus cmd
        val pendingCmd = Reg(UInt(log2Up(pendingMax + 1) bits)) init (0)
        val pendingCmdNext = pendingCmd + iBus.cmd.fire.asUInt - iBus.rsp.fire.asUInt
        pendingCmd := pendingCmdNext

        iBus.cmd.valid := input.valid && output.ready && pendingCmd =/= pendingMax
        iBus.cmd.pc := input.payload(31 downto 2) @@ "00"
      }

      case class FetchRsp() extends Bundle {
        val pc = UInt(32 bits)
        val rsp = IBusSimpleRsp()
        val isRvc = Bool
      }

      def recursive[T](that : T,depth : Int, func : (T) => T) : T = depth match {
        case 0 => that
        case _ => recursive(func(that), depth -1, func)
      }

      val iBusRsp = new Area {
        val inputFirstStage = if(relaxedPcCalculation) iBusCmd.output.m2sPipe(flush) else iBusCmd.output.m2sPipe().throwWhen(flush)
        val input = recursive[Stream[UInt]](inputFirstStage, cmdToRspStageCount - 1, x => x.m2sPipe(flush))//iBusCmd.output.m2sPipe(flush)// ASYNC .throwWhen(flush)

        //Manage flush for iBus transactions in flight
        val discardCounter = Reg(UInt(log2Up(pendingMax + 1) bits)) init (0)
        discardCounter := discardCounter - (iBus.rsp.fire && discardCounter =/= 0).asUInt
        when(flush) {
          discardCounter := (if(relaxedPcCalculation) iBusCmd.pendingCmdNext else iBusCmd.pendingCmd - iBus.rsp.fire.asUInt)
        }


//        val rsp = recursive[Stream[IBusSimpleRsp]](rspUnbuffered, cmdToRspStageCount, x => x.s2mPipe(flush))
        val rspBuffer = StreamFifoLowLatency(IBusSimpleRsp(), cmdToRspStageCount)
        rspBuffer.io.push << iBus.rsp.throwWhen(discardCounter =/= 0).toStream
        rspBuffer.io.flush := flush

        val fetchRsp = FetchRsp()
        fetchRsp.pc := input.payload
        fetchRsp.rsp := rspBuffer.io.pop.payload
        fetchRsp.rsp.error.clearWhen(!rspBuffer.io.pop.valid) //Avoid interference with instruction injection from the debug plugin


        def outputGen = StreamJoin(Seq(input, rspBuffer.io.pop), fetchRsp)
        val output = if(rspStageGen) outputGen.m2sPipe(flush) else outputGen
      }

      val decompressor = ifGen(decodePcGen)(new Area{
        def input = iBusRsp.output
        val output = Stream(FetchRsp())

        val bufferValid = RegInit(False)
        val bufferError = Reg(Bool)
        val bufferData = Reg(Bits(16 bits))

        val raw = Mux(
          sel = bufferValid,
          whenTrue = input.rsp.inst(15 downto 0) ## bufferData,
          whenFalse = input.rsp.inst(31 downto 16) ## (input.pc(1) ? input.rsp.inst(31 downto 16) | input.rsp.inst(15 downto 0))
        )
        val isRvc = raw(1 downto 0) =/= 3
        val decompressed = RvcDecompressor(raw(15 downto 0))
        output.valid := isRvc ? (bufferValid || input.valid) | (input.valid && (bufferValid || !input.pc(1)))
        output.pc := input.pc
        output.isRvc := isRvc
        output.rsp.inst := isRvc ? decompressed | raw
        output.rsp.error := (bufferValid && bufferError) || (input.valid && input.rsp.error && (!isRvc || (isRvc && !bufferValid)))
        input.ready := (bufferValid ? (!isRvc && output.ready) | (input.pc(1) || output.ready))


        bufferValid clearWhen(output.fire)
        when(input.ready){
          when(input.valid) {
            bufferValid := !(!isRvc && !input.pc(1) && !bufferValid) && !(isRvc && input.pc(1))
            bufferError := input.rsp.error
            bufferData := input.rsp.inst(31 downto 16)
          }
        }
        bufferValid.clearWhen(flush)
      })

      def condApply[T](that : T, cond : Boolean)(func : (T) => T) = if(cond)func(that) else that
      val injector = new Area {
        val inputBeforeHalt = condApply(if(decodePcGen) decompressor.output else iBusRsp.output, injectorReadyCutGen)(_.s2mPipe(flush))
        val input =  inputBeforeHalt.haltWhen(fetcherHalt)
        val stage = input.m2sPipe(flush || decode.arbitration.isRemoved)

        if(decodePcGen){
          decodeNextPcValid := True
          decodeNextPc := decodePc.pcReg
        }else {
          decodeNextPcValid := RegNext(inputBeforeHalt.isStall)
          decodeNextPc := decode.input(PC)
        }

        stage.ready := !decode.arbitration.isStuck
        decode.arbitration.isValid := stage.valid
        decode.insert(PC) := (if(decodePcGen) decodePc.pcReg else stage.pc)
        decode.insert(INSTRUCTION) := stage.rsp.inst
        decode.insert(INSTRUCTION_ANTICIPATED) := Mux(decode.arbitration.isStuck, decode.input(INSTRUCTION), input.rsp.inst)
        decode.insert(INSTRUCTION_READY) := True
        if(compressedGen) decode.insert(IS_RVC) := stage.isRvc

        if(catchAccessFault){
          decodeExceptionPort.valid := decode.arbitration.isValid && stage.rsp.error
          decodeExceptionPort.code  := 1
          decodeExceptionPort.badAddr := decode.input(PC)
        }

        prediction match {
          case `NONE` =>
          case `STATIC` => {
            val imm = IMM(decode.input(INSTRUCTION))

            val conditionalBranchPrediction = (prediction match {
              case `STATIC` =>  imm.b_sext.msb
              //case `DYNAMIC` => input(HISTORY_LINE).history.msb
            })
            decodePrediction.cmd.hadBranch := decode.input(BRANCH_CTRL) === BranchCtrlEnum.JAL || (decode.input(BRANCH_CTRL) === BranchCtrlEnum.B && conditionalBranchPrediction)

            predictionJumpInterface.valid := decodePrediction.cmd.hadBranch && decode.arbitration.isFiring //TODO OH Doublon de priorité
            predictionJumpInterface.payload := decode.input(PC) + ((decode.input(BRANCH_CTRL) === BranchCtrlEnum.JAL) ? imm.j_sext | imm.b_sext).asUInt


//            if(catchAddressMisaligned) {
//              predictionExceptionPort.valid := input(INSTRUCTION_READY) && input(PREDICTION_HAD_BRANCHED) && arbitration.isValid && predictionJumpInterface.payload(1 downto 0) =/= 0
//              predictionExceptionPort.code := 0
//              predictionExceptionPort.badAddr := predictionJumpInterface.payload
//            }
          }
        }
      }
    }
  }
}