package vexriscv.plugin

import spinal.core._
import spinal.lib._
import vexriscv._
import vexriscv.Riscv._
import vexriscv.ip.fpu._

class FpuPlugin(externalFpu : Boolean = false,
                p : FpuParameter) extends Plugin[VexRiscv]{

  object FPU_ENABLE extends Stageable(Bool())
  object FPU_COMMIT extends Stageable(Bool())
  object FPU_COMMIT_SYNC extends Stageable(Bool())
  object FPU_COMMIT_LOAD extends Stageable(Bool())
  object FPU_RSP extends Stageable(Bool())
  object FPU_FORKED extends Stageable(Bool())
  object FPU_OPCODE extends Stageable(FpuOpcode())
  object FPU_ARG extends Stageable(Bits(2 bits))
  object FPU_FORMAT extends Stageable(FpuFormat())

  var port : FpuPort = null

  override def setup(pipeline: VexRiscv): Unit = {
    import pipeline.config._

    type ENC = (Stageable[_ <: BaseType],Any)

    val intRfWrite = List[ENC](
      FPU_ENABLE -> True,
      FPU_COMMIT -> False,
      FPU_RSP -> True,
      REGFILE_WRITE_VALID -> True,
      BYPASSABLE_EXECUTE_STAGE -> False,
      BYPASSABLE_MEMORY_STAGE  -> False
    )

    val floatRfWrite = List[ENC](
      FPU_ENABLE -> True,
      FPU_COMMIT -> True,
      FPU_RSP -> False
    )

    val addSub  = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.ADD
    val mul     = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.MUL
    val fma     = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.FMA
    val div     = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.DIV
    val sqrt    = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.SQRT
    val fsgnj   = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.SGNJ
    val fminMax = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.MIN_MAX
    val fmvWx   = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.FMV_W_X :+ RS1_USE -> True
    val fcvtI2f = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.I2F     :+ RS1_USE -> True
    val fcvtxx  = floatRfWrite :+ FPU_OPCODE -> FpuOpcode.FCVT_X_X

    val fcmp    = intRfWrite   :+ FPU_OPCODE -> FpuOpcode.CMP
    val fclass  = intRfWrite   :+ FPU_OPCODE -> FpuOpcode.FCLASS
    val fmvXw   = intRfWrite   :+ FPU_OPCODE -> FpuOpcode.FMV_X_W
    val fcvtF2i = intRfWrite   :+ FPU_OPCODE -> FpuOpcode.F2I

    val fl = List[ENC](
      FPU_ENABLE -> True,
      FPU_OPCODE -> FpuOpcode.LOAD,
      FPU_COMMIT -> True,
      FPU_RSP -> False
    )

    val fs = List[ENC](
      FPU_ENABLE -> True,
      FPU_OPCODE -> FpuOpcode.STORE,
      FPU_COMMIT -> False,
      FPU_RSP -> True
    )


    def arg(v : Int) = FPU_ARG -> U(v, 2 bits)
    val decoderService = pipeline.service(classOf[DecoderService])
    decoderService.addDefault(FPU_ENABLE, False)

    val f32 = FPU_FORMAT -> FpuFormat.FLOAT
    val f64 = FPU_FORMAT -> FpuFormat.DOUBLE

    decoderService.add(List(
      FADD_S    -> (addSub  :+ f32 :+ arg(0)),
      FSUB_S    -> (addSub  :+ f32 :+ arg(1)),
      FMADD_S   -> (fma     :+ f32 :+ arg(0)),
      FMSUB_S   -> (fma     :+ f32 :+ arg(2)),
      FNMADD_S  -> (fma     :+ f32 :+ arg(3)),
      FNMSUB_S  -> (fma     :+ f32 :+ arg(1)),
      FMUL_S    -> (mul     :+ f32 :+ arg(0)),
      FDIV_S    -> (div     :+ f32 ),
      FSQRT_S   -> (sqrt    :+ f32 ),
      FLW       -> (fl      :+ f32 ),
      FSW       -> (fs      :+ f32 ),
      FCVT_S_WU -> (fcvtI2f :+ f32 :+ arg(0)),
      FCVT_S_W  -> (fcvtI2f :+ f32 :+ arg(1)),
      FCVT_WU_S -> (fcvtF2i :+ f32 :+ arg(0)),
      FCVT_W_S ->  (fcvtF2i :+ f32 :+ arg(1)),
      FCLASS_S  -> (fclass  :+ f32 ),
      FLE_S     -> (fcmp    :+ f32 :+ arg(0)),
      FEQ_S     -> (fcmp    :+ f32 :+ arg(2)),
      FLT_S     -> (fcmp    :+ f32 :+ arg(1)),
      FSGNJ_S   -> (fsgnj   :+ f32 :+ arg(0)),
      FSGNJN_S  -> (fsgnj   :+ f32 :+ arg(1)),
      FSGNJX_S  -> (fsgnj   :+ f32 :+ arg(2)),
      FMIN_S    -> (fminMax :+ f32 :+ arg(0)),
      FMAX_S    -> (fminMax :+ f32 :+ arg(1)),
      FMV_X_W   -> (fmvXw   :+ f32 ),
      FMV_W_X   -> (fmvWx   :+ f32 )
    ))

    if(p.withDouble){
      decoderService.add(List(
        FADD_D    -> (addSub  :+ f64 :+ arg(0)),
        FSUB_D    -> (addSub  :+ f64 :+ arg(1)),
        FMADD_D   -> (fma     :+ f64 :+ arg(0)),
        FMSUB_D   -> (fma     :+ f64 :+ arg(2)),
        FNMADD_D  -> (fma     :+ f64 :+ arg(3)),
        FNMSUB_D  -> (fma     :+ f64 :+ arg(1)),
        FMUL_D    -> (mul     :+ f64 :+ arg(0)),
        FDIV_D    -> (div     :+ f64 ),
        FSQRT_D   -> (sqrt    :+ f64 ),
        FLW       -> (fl      :+ f64 ),
        FSW       -> (fs      :+ f64 ),
        FCVT_S_WU -> (fcvtI2f :+ f64 :+ arg(0)),
        FCVT_S_W  -> (fcvtI2f :+ f64 :+ arg(1)),
        FCVT_WU_D -> (fcvtF2i :+ f64 :+ arg(0)),
        FCVT_W_D  -> (fcvtF2i :+ f64 :+ arg(1)),
        FCLASS_D  -> (fclass  :+ f64 ),
        FLE_D     -> (fcmp    :+ f64 :+ arg(0)),
        FEQ_D     -> (fcmp    :+ f64 :+ arg(2)),
        FLT_D     -> (fcmp    :+ f64 :+ arg(1)),
        FSGNJ_D   -> (fsgnj   :+ f64 :+ arg(0)),
        FSGNJN_D  -> (fsgnj   :+ f64 :+ arg(1)),
        FSGNJX_D  -> (fsgnj   :+ f64 :+ arg(2)),
        FMIN_D    -> (fminMax :+ f64 :+ arg(0)),
        FMAX_D    -> (fminMax :+ f64 :+ arg(1)),
        FCVT_D_S  -> (fcvtxx :+ f32),
        FCVT_S_D  -> (fcvtxx :+ f64)
      ))
    }
    //TODO FMV_X_X + doubles

    port = FpuPort(p)
    if(externalFpu) master(port)

    val dBusEncoding =  pipeline.service(classOf[DBusEncodingService])
    dBusEncoding.addLoadWordEncoding(FLW)
    dBusEncoding.addStoreWordEncoding(FSW)
  }

  override def build(pipeline: VexRiscv): Unit = {
    import pipeline._
    import pipeline.config._
    import Riscv._

    val internal = !externalFpu generate pipeline plug new Area{
      val fpu = FpuCore(1, p)
      fpu.io.port(0).cmd << port.cmd
      fpu.io.port(0).commit << port.commit
      fpu.io.port(0).rsp >> port.rsp
      fpu.io.port(0).completion <> port.completion
    }


    val csr = pipeline plug new Area{
      val pendings = Reg(UInt(5 bits)) init(0)
      pendings := pendings + U(port.cmd.fire) - port.completion.count

      val hasPending = pendings =/= 0

      val flags = Reg(FpuFlags())
      flags.NV init(False) setWhen(port.completion.flag.NV)
      flags.DZ init(False) setWhen(port.completion.flag.DZ)
      flags.OF init(False) setWhen(port.completion.flag.OF)
      flags.UF init(False) setWhen(port.completion.flag.UF)
      flags.NX init(False) setWhen(port.completion.flag.NX)

      val service = pipeline.service(classOf[CsrInterface])
      val rm = Reg(Bits(3 bits)) init(0)

      service.rw(CSR.FCSR,   5, rm)
      service.rw(CSR.FCSR,   0, flags)
      service.rw(CSR.FRM,    0, rm)
      service.rw(CSR.FFLAGS, 0, flags)

      val csrActive = service.duringAny()
      execute.arbitration.haltByOther setWhen(csrActive && hasPending) // pessimistic

      val fs = Reg(Bits(2 bits)) init(1)
      when(hasPending){
        fs := 3 //DIRTY
      }
      service.rw(CSR.SSTATUS, 13, fs)
    }

    decode plug new Area{
      import decode._

      //Maybe it might be better to not fork before fire to avoid RF stall on commits
      val forked = Reg(Bool) setWhen(port.cmd.fire) clearWhen(!arbitration.isStuck) init(False)

      val hazard = csr.pendings.msb || csr.csrActive

      arbitration.haltItself setWhen(arbitration.isValid && input(FPU_ENABLE) && hazard)
      arbitration.haltItself setWhen(port.cmd.isStall)

      val iRoundMode = input(INSTRUCTION)(funct3Range)
      val roundMode = (input(INSTRUCTION)(funct3Range) === B"111") ? csr.rm | input(INSTRUCTION)(funct3Range)

      port.cmd.valid     := arbitration.isValid && input(FPU_ENABLE) && !forked && !hazard
      port.cmd.opcode    := input(FPU_OPCODE)
      port.cmd.arg       := input(FPU_ARG)
      port.cmd.rs1       := ((input(FPU_OPCODE) === FpuOpcode.STORE) ? input(INSTRUCTION)(rs2Range).asUInt | input(INSTRUCTION)(rs1Range).asUInt)
      port.cmd.rs2       := input(INSTRUCTION)(rs2Range).asUInt
      port.cmd.rs3       := input(INSTRUCTION)(rs3Range).asUInt
      port.cmd.rd        := input(INSTRUCTION)(rdRange).asUInt
      port.cmd.format    := (if(p.withDouble) input(FPU_FORMAT) else FpuFormat.FLOAT())
      port.cmd.roundMode := roundMode.as(FpuRoundMode())

      insert(FPU_FORKED) := forked || port.cmd.fire

      insert(FPU_COMMIT_SYNC) := List(FpuOpcode.LOAD, FpuOpcode.FMV_W_X, FpuOpcode.I2F).map(_ === input(FPU_OPCODE)).orR
      insert(FPU_COMMIT_LOAD) := input(FPU_OPCODE) === FpuOpcode.LOAD
    }

    writeBack plug new Area{
      import writeBack._

      val dBusEncoding =  pipeline.service(classOf[DBusEncodingService])
      val isRsp = input(FPU_FORKED) && input(FPU_RSP)
      val isCommit = input(FPU_FORKED) && input(FPU_COMMIT)

      //Manage $store and port.rsp
      port.rsp.ready := False
      when(isRsp){
        when(arbitration.isValid) {
          dBusEncoding.bypassStore(port.rsp.value)
          output(REGFILE_WRITE_DATA) := port.rsp.value
        }
        when(!port.rsp.valid){
          arbitration.haltByOther := True
        } elsewhen(!arbitration.haltItself){
          port.rsp.ready := True
        }
      }

      // Manage $load
      val commit = Stream(FpuCommit(p))
      commit.valid := isCommit && !arbitration.isStuck
      commit.value := (input(FPU_COMMIT_LOAD) ? output(DBUS_DATA) | input(RS1))
      commit.write := arbitration.isValid && !arbitration.removeIt
      commit.sync := input(FPU_COMMIT_SYNC)

      when(arbitration.isValid && !commit.ready){
        arbitration.haltByOther := True
      }

      port.commit <-/< commit
    }

    pipeline.stages.dropRight(1).foreach(s => s.output(FPU_FORKED) clearWhen(s.arbitration.isStuck))

    Component.current.afterElaboration{
      pipeline.stages.tail.foreach(_.input(FPU_FORKED).init(False))
    }
  }
}
