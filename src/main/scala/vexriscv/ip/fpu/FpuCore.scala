package vexriscv.ip.fpu

import spinal.core._
import spinal.lib._
import spinal.lib.eda.bench.{Bench, Rtl, XilinxStdTargets}

import scala.collection.mutable.ArrayBuffer

object FpuDivSqrtIterationState extends SpinalEnum{
  val IDLE, YY, XYY, Y2_XYY, DIV, _15_XYY2, Y_15_XYY2, Y_15_XYY2_RESULT, SQRT = newElement()
}

//TODO cleanup rounding
case class FpuCore( portCount : Int, p : FpuParameter) extends Component{
  val io = new Bundle {
    val port = Vec(slave(FpuPort(p)), portCount)
  }

  val portCountWidth = log2Up(portCount)
  val Source = HardType(UInt(portCountWidth bits))
  val exponentOne = (1 << p.internalExponentSize-1) - 1
  val exponentF32Subnormal = exponentOne-127
  val exponentF64Subnormal = exponentOne-1023
  val exponentF32Infinity = exponentOne+127+1
  val exponentF64Infinity = exponentOne+1023+1

  val rfLockCount = 5
  val lockIdType = HardType(UInt(log2Up(rfLockCount) bits))

  def whenDouble(format : FpuFormat.C)(yes : => Unit)(no : => Unit): Unit ={
    if(p.withDouble) when(format === FpuFormat.DOUBLE) { yes } otherwise{ no }
    if(!p.withDouble) no
  }

  def muxDouble[T <: Data](format : FpuFormat.C)(yes : => T)(no : => T): T ={
    if(p.withDouble) ((format === FpuFormat.DOUBLE) ? { yes } | { no })
    else no
  }

  case class RfReadInput() extends Bundle{
    val source = Source()
    val opcode = p.Opcode()
    val rs1, rs2, rs3 = p.rfAddress()
    val rd = p.rfAddress()
    val arg = p.Arg()
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }

  case class RfReadOutput() extends Bundle{
    val source = Source()
    val opcode = p.Opcode()
    val lockId = lockIdType()
    val rs1, rs2, rs3 = p.internalFloating()
    val rd = p.rfAddress()
    val arg = p.Arg()
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }


  case class LoadInput() extends Bundle{
    val source = Source()
    val rd = p.rfAddress()
    val lockId = lockIdType()
    val i2f = Bool()
    val arg = Bits(2 bits)
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }

  case class ShortPipInput() extends Bundle{
    val source = Source()
    val opcode = p.Opcode()
    val rs1, rs2 = p.internalFloating()
    val lockId = lockIdType()
    val rd = p.rfAddress()
    val value = Bits(32 bits)
    val arg = Bits(2 bits)
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }

  case class MulInput() extends Bundle{
    val source = Source()
    val rs1, rs2, rs3 = p.internalFloating()
    val rd = p.rfAddress()
    val lockId = lockIdType()
    val add = Bool()
    val divSqrt = Bool()
    val msb1, msb2 = Bool() //allow usage of msb bits of mul
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }


  case class DivSqrtInput() extends Bundle{
    val source = Source()
    val rs1, rs2 = p.internalFloating()
    val rd = p.rfAddress()
    val lockId = lockIdType()
    val div = Bool()
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }


  case class AddInput() extends Bundle{
    val source = Source()
    val rs1, rs2 = p.internalFloating()
    val rd = p.rfAddress()
    val lockId = lockIdType()
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }


  case class MergeInput() extends Bundle{
    val source = Source()
    val lockId = lockIdType()
    val rd = p.rfAddress()
    val value = p.writeFloating()
    val scrap = Bool()
    val roundMode = FpuRoundMode()
    val format = p.withDouble generate FpuFormat()
  }

  case class RoundOutput() extends Bundle{
    val source = Source()
    val lockId = lockIdType()
    val rd = p.rfAddress()
    val value = p.internalFloating()
    val format = p.withDouble generate FpuFormat()
  }

  val rf = new Area{
    case class Entry() extends Bundle{
      val value = p.internalFloating()
      val boxed = p.withDouble generate Bool()
    }
    val ram = Mem(Entry(), 32*portCount)
    val lock = for(i <- 0 until rfLockCount) yield new Area{
      val valid = RegInit(False)
      val source = Reg(Source())
      val address = Reg(p.rfAddress)
      val id = Reg(UInt(log2Up(rfLockCount) bits))
      val commited = Reg(Bool)
      val write = Reg(Bool)
    }
    val lockFree = !lock.map(_.valid).andR
    val lockFreeId = OHMasking.first(lock.map(!_.valid))
  }

  val completion = for(source <- 0 until portCount) yield new Area{
    def port = io.port(source)
    port.completion.flag.NV := False
    port.completion.flag.DZ := False
    port.completion.flag.OF := False
    port.completion.flag.UF := False
    port.completion.flag.NX := False

    val increments = ArrayBuffer[Bool]()

    afterElaboration{
      port.completion.count := increments.map(_.asUInt.resize(log2Up(increments.size + 1))).reduceBalancedTree(_ + _)
    }
  }

  val commitFork = new Area{
    val load, commit = Vec(Stream(FpuCommit(p)), portCount)
    for(i <- 0 until portCount){
      val fork = new StreamFork(FpuCommit(p), 2)
      fork.io.input << io.port(i).commit
      fork.io.outputs(0) >> load(i)
      fork.io.outputs(1) >> commit(i)
    }
  }

  val commitLogic = for(source <- 0 until portCount) yield new Area{
    val fire = False
    val target, hit = Reg(UInt(log2Up(rfLockCount) bits)) init(0)
    when(fire){
      hit := hit + 1
    }

    commitFork.commit(source).ready := False
    when(commitFork.commit(source).valid) {
      for (lock <- rf.lock) {
        when(lock.valid && lock.source === source && lock.id === hit) {
          fire := True
          lock.commited := True
          lock.write := commitFork.commit(source).write
          commitFork.commit(source).ready := True
        }
      }
    }
  }

  //TODO nan boxing decoding
  val read = new Area{
    val arbiter = StreamArbiterFactory.noLock.lowerFirst.build(FpuCmd(p), portCount)
    arbiter.io.inputs <> Vec(io.port.map(_.cmd))

    val s0 = Stream(RfReadInput())
    s0.arbitrationFrom(arbiter.io.output)
    s0.source := arbiter.io.chosen
    s0.payload.assignSomeByName(arbiter.io.output.payload)

    val useRs1, useRs2, useRs3, useRd = False
    switch(s0.opcode){
      is(p.Opcode.LOAD)    {  useRd := True }
      is(p.Opcode.STORE)   { useRs1 := True }
      is(p.Opcode.ADD)     { useRd  := True; useRs1 := True; useRs2 := True }
      is(p.Opcode.MUL)     { useRd  := True; useRs1 := True; useRs2 := True }
      is(p.Opcode.DIV)     { useRd  := True; useRs1 := True; useRs2 := True }
      is(p.Opcode.SQRT)    { useRd  := True; useRs1 := True }
      is(p.Opcode.FMA)     { useRd  := True; useRs1 := True; useRs2 := True; useRs3 := True }
      is(p.Opcode.I2F)     { useRd  := True }
      is(p.Opcode.F2I)     { useRs1 := True }
      is(p.Opcode.MIN_MAX) { useRd  := True; useRs1 := True; useRs2 := True }
      is(p.Opcode.CMP)     { useRs1 := True; useRs2 := True }
      is(p.Opcode.SGNJ)    { useRd  := True; useRs1 := True; useRs2 := True }
      is(p.Opcode.FMV_X_W) { useRs1 := True }
      is(p.Opcode.FMV_W_X) { useRd  := True }
      is(p.Opcode.FCLASS ) { useRs1  := True }
    }

    val hits = List((useRs1, s0.rs1), (useRs2, s0.rs2), (useRs3, s0.rs3), (useRd, s0.rd)).map{case (use, reg) => use && rf.lock.map(l => l.valid && l.source === s0.source && l.address === reg).orR}
    val hazard = hits.orR
    when(s0.fire && useRd){
      for(i <- 0 until portCount){
        when(s0.source === i){
          commitLogic(i).target := commitLogic(i).target + 1
        }
      }
      for(i <- 0 until rfLockCount){
        when(rf.lockFreeId(i)){
          rf.lock(i).valid := True
          rf.lock(i).source := s0.source
          rf.lock(i).address := s0.rd
          rf.lock(i).id := commitLogic.map(_.target).read(s0.source)
          rf.lock(i).commited := False
        }
      }
    }

    val s1 = s0.haltWhen(hazard || !rf.lockFree).m2sPipe()
    val output = s1.swapPayload(RfReadOutput())
    val s1LockId = RegNextWhen(OHToUInt(rf.lockFreeId), !output.isStall)
    val rs1Entry = rf.ram.readSync(s0.source @@ s0.rs1,enable = !output.isStall)
    val rs2Entry = rf.ram.readSync(s0.source @@ s0.rs2,enable = !output.isStall)
    val rs3Entry = rf.ram.readSync(s0.source @@ s0.rs3,enable = !output.isStall)
    output.source := s1.source
    output.opcode := s1.opcode
    output.lockId := s1LockId
    output.arg := s1.arg
    output.roundMode := s1.roundMode
    output.rd := s1.rd
    output.rs1 := rs1Entry.value
    output.rs2 := rs2Entry.value
    output.rs3 := rs3Entry.value
    if(p.withDouble){
      output.format := s1.format
      val store = s1.opcode === FpuOpcode.STORE ||s1.opcode === FpuOpcode.FMV_X_W
      when(store){ //Pass through
        output.format := rs1Entry.boxed ? FpuFormat.FLOAT | FpuFormat.DOUBLE
      } elsewhen(s1.format === FpuFormat.FLOAT =/= rs1Entry.boxed){
        output.rs1.setNanQuiet
        output.rs1.sign := False
      }
      when(s1.format === FpuFormat.FLOAT =/= rs2Entry.boxed){
        output.rs2.setNanQuiet
        output.rs2.sign := False
      }
      when(s1.format === FpuFormat.FLOAT =/= rs3Entry.boxed){
        output.rs3.setNanQuiet
      }
    }
  }

  val decode = new Area{
    val input = read.output.combStage()
    input.ready := False

    val loadHit = List(FpuOpcode.LOAD, FpuOpcode.FMV_W_X, FpuOpcode.I2F).map(input.opcode === _).orR
    val load = Stream(LoadInput())
    load.valid := input.valid && loadHit
    input.ready setWhen(loadHit && load.ready)
    load.payload.assignSomeByName(read.output.payload)
    load.i2f := input.opcode === FpuOpcode.I2F

    val shortPipHit = List(FpuOpcode.STORE, FpuOpcode.F2I, FpuOpcode.CMP, FpuOpcode.MIN_MAX, FpuOpcode.SGNJ, FpuOpcode.FMV_X_W, FpuOpcode.FCLASS).map(input.opcode === _).orR
    val shortPip = Stream(ShortPipInput())
    input.ready setWhen(shortPipHit && shortPip.ready)
    shortPip.valid := input.valid && shortPipHit
    shortPip.payload.assignSomeByName(read.output.payload)

    val divSqrtHit = input.opcode === p.Opcode.DIV ||  input.opcode === p.Opcode.SQRT
    val divSqrt = Stream(DivSqrtInput())
    if(p.withDivSqrt) {
      input.ready setWhen (divSqrtHit && divSqrt.ready)
      divSqrt.valid := input.valid && divSqrtHit
      divSqrt.payload.assignSomeByName(read.output.payload)
      divSqrt.div := input.opcode === p.Opcode.DIV
    }

    val fmaHit = input.opcode === p.Opcode.FMA
    val mulHit = input.opcode === p.Opcode.MUL || fmaHit
    val mul = Stream(MulInput())
    val divSqrtToMul = Stream(MulInput())

    if(p.withMul) {
      input.ready setWhen (mulHit && mul.ready && !divSqrtToMul.valid)
      mul.valid := input.valid && mulHit || divSqrtToMul.valid

      divSqrtToMul.ready := mul.ready
      mul.payload := divSqrtToMul.payload
      when(!divSqrtToMul.valid) {
        mul.payload.assignSomeByName(read.output.payload)
        mul.add := fmaHit
        mul.divSqrt := False
        mul.msb1 := True
        mul.msb2 := True
        mul.rs2.sign.allowOverride();
        mul.rs2.sign := read.output.rs2.sign ^ input.arg(0)
        mul.rs3.sign.allowOverride();
        mul.rs3.sign := read.output.rs3.sign ^ input.arg(1)
      }
    }

    val addHit = input.opcode === p.Opcode.ADD
    val add = Stream(AddInput())
    val mulToAdd = Stream(AddInput())


    if(p.withAdd) {
      input.ready setWhen (addHit && add.ready && !mulToAdd.valid)
      add.valid := input.valid && addHit || mulToAdd.valid

      mulToAdd.ready := add.ready
      add.payload := mulToAdd.payload
      when(!mulToAdd.valid) {
        add.payload.assignSomeByName(read.output.payload)
        add.rs2.sign.allowOverride;
        add.rs2.sign := read.output.rs2.sign ^ input.arg(0)
      }
    }
  }

  val load = new Area{

    case class S0() extends Bundle{
      val source = Source()
      val lockId = lockIdType()
      val rd = p.rfAddress()
      val value = p.storeLoadType()
      val i2f = Bool()
      val arg = Bits(2 bits)
      val roundMode = FpuRoundMode()
      val format = p.withDouble generate FpuFormat()
    }

    val s0 = new Area{
      val input = decode.load.stage()
      val filtred = commitFork.load.map(port => port.takeWhen(port.sync))
      def feed = filtred(input.source)
      val hazard = !feed.valid

      val output = input.haltWhen(hazard).swapPayload(S0())
      filtred.foreach(_.ready := False)
      feed.ready := input.valid && output.ready
      output.source := input.source
      output.lockId := input.lockId
      output.rd := input.rd
      output.value := feed.value
      output.i2f := input.i2f
      output.arg := input.arg
      output.roundMode := input.roundMode
      if(p.withDouble) {
        output.format := input.format
        when(!input.i2f && input.format === FpuFormat.DOUBLE && output.value(63 downto 32).andR){ //Detect boxing
          output.format := FpuFormat.FLOAT
        }
      }

    }

    val s1 = new Area{
      val input = s0.output.stage()
      val busy = False

      val f32 = new Area{
        val mantissa = input.value(0, 23 bits).asUInt
        val exponent = input.value(23, 8 bits).asUInt
        val sign     = input.value(31)
      }
      val f64 = p.withDouble generate new Area{
        val mantissa = input.value(0, 52 bits).asUInt
        val exponent = input.value(52, 11 bits).asUInt
        val sign     = input.value(63)
      }

      val recodedExpOffset = UInt(p.internalExponentSize bits)
      val passThroughFloat = p.internalFloating()
      passThroughFloat.special := False

      whenDouble(input.format){
        passThroughFloat.sign := f64.sign
        passThroughFloat.exponent := f64.exponent.resized
        passThroughFloat.mantissa := f64.mantissa
        recodedExpOffset := exponentF64Subnormal
      } {
        passThroughFloat.sign := f32.sign
        passThroughFloat.exponent := f32.exponent.resized
        passThroughFloat.mantissa := f32.mantissa << (if (p.withDouble) 29 else 0)
        recodedExpOffset := exponentF32Subnormal
      }


      val manZero = passThroughFloat.mantissa === 0
      val expZero = passThroughFloat.exponent === 0
      val expOne =  passThroughFloat.exponent(7 downto 0).andR
      if(p.withDouble) {
        expZero.clearWhen(input.format === FpuFormat.DOUBLE && input.value(62 downto 60) =/= 0)
        expOne.clearWhen(input.format === FpuFormat.DOUBLE && input.value(62 downto 60) =/= 7)
      }

      val isZero      =  expZero &&  manZero
      val isSubnormal =  expZero && !manZero
      val isInfinity  =  expOne  &&  manZero
      val isNan       =  expOne  && !manZero


      val fsm = new Area{
        val done, boot, patched = Reg(Bool())
        val ohInputWidth = 32 max p.internalMantissaSize
        val ohInput = Bits(ohInputWidth bits).assignDontCare()
        when(!input.i2f) {
          if(!p.withDouble) ohInput := input.value(0, 23 bits) << 9
          if( p.withDouble) ohInput := passThroughFloat.mantissa.asBits
        } otherwise {
          ohInput(ohInputWidth-32-1 downto 0) := 0
          ohInput(ohInputWidth-32, 32 bits) := input.value(31 downto 0)
        }

        val i2fZero = Reg(Bool)

        val shift = new Area{
          val by = Reg(UInt(log2Up(ohInputWidth) bits))
          val input = UInt(ohInputWidth bits).assignDontCare()
          var logic = input
          for(i <- by.range){
            logic \= by(i) ? (logic |<< (BigInt(1) << i)) | logic
          }
          val output = RegNextWhen(logic, !done)
        }
        shift.input := (ohInput.asUInt |<< 1).resized

        val subnormalShiftOffset = if(!p.withDouble) U(0) else ((input.format === FpuFormat.DOUBLE) ? U(0) | U(0)) //TODO remove ?
        val subnormalExpOffset = if(!p.withDouble) U(0) else ((input.format === FpuFormat.DOUBLE)   ? U(0) | U(0))

        when(input.valid && (input.i2f || isSubnormal) && !done){
          busy := True
          when(boot){
            when(input.i2f && !patched && input.value(31) && input.arg(0)){
              input.value.getDrivingReg(0, 32 bits) := B(input.value.asUInt.twoComplement(True).resize(32 bits))
              patched := True
            } otherwise {
              shift.by := OHToUInt(OHMasking.first((ohInput).reversed)) + (input.i2f ? U(0) | subnormalShiftOffset)
              boot := False
              i2fZero := input.value(31 downto 0) === 0
            }
          } otherwise {
            done := True
          }
        }

        val expOffset = (UInt(p.internalExponentSize bits))
        expOffset := 0
        when(isSubnormal){
          expOffset := (shift.by-subnormalExpOffset).resized
        }

        when(!input.isStall){
          done := False
          boot := True
          patched := False
        }
      }


      val i2fSign = fsm.patched
      val (i2fHigh, i2fLow) = fsm.shift.output.splitAt(if(p.withDouble) 0 else widthOf(input.value)-24)
      val scrap = i2fLow =/= 0

      val recoded = p.internalFloating()
      recoded.mantissa := passThroughFloat.mantissa
      recoded.exponent := (passThroughFloat.exponent -^ fsm.expOffset + recodedExpOffset).resized
      recoded.sign     := passThroughFloat.sign
      recoded.setNormal
      when(isZero){recoded.setZero}
      when(isInfinity){recoded.setInfinity}
      when(isNan){recoded.setNan}

      val output = input.haltWhen(busy).swapPayload(MergeInput())
      output.source := input.source
      output.lockId := input.lockId
      output.roundMode := input.roundMode
      if(p.withDouble) {
        output.format := input.format
      }
      output.rd := input.rd
      output.value.sign      := recoded.sign
      output.value.exponent  := recoded.exponent
      output.value.mantissa  := recoded.mantissa @@ U"0"
      output.value.special   := recoded.special
      output.scrap := False
      when(input.i2f){
        output.value.sign := i2fSign
        output.value.exponent := (U(exponentOne+31) - fsm.shift.by).resized
        output.value.setNormal
        output.scrap := scrap
        when(fsm.i2fZero) { output.value.setZero }
      }

      when(input.i2f || isSubnormal){
        output.value.mantissa := U(i2fHigh) @@ (if(p.withDouble) U"0" else U"")
      }
    }
  }

  val shortPip = new Area{
    val input = decode.shortPip.stage()

    val rfOutput = Stream(MergeInput())

    val result = p.storeLoadType().assignDontCare()

    val flag = io.port(input.source).completion.flag

    val halt = False
    val recodedResult =  p.storeLoadType()
    val f32 = new Area{
      val exp = (input.rs1.exponent - (exponentOne-127)).resize(8 bits)
      val man = CombInit(input.rs1.mantissa(if(p.withDouble) 51 downto 29 else 22 downto 0))
    }
    val f64 = p.withDouble generate new Area{
      val exp = (input.rs1.exponent - (exponentOne-1023)).resize(11 bits)
      val man = CombInit(input.rs1.mantissa)
    }

    whenDouble(input.format){
      recodedResult := input.rs1.sign ## f64.exp ## f64.man
    } {
      recodedResult := (if(p.withDouble) B"xFFFFFFFF" else B"") ## input.rs1.sign ## f32.exp ## f32.man
    }

    val expSubnormalThreshold = muxDouble[UInt](input.format)(exponentF64Subnormal)(exponentF32Subnormal)
    val expInSubnormalRange = input.rs1.exponent <= expSubnormalThreshold
    val isSubnormal = !input.rs1.special && expInSubnormalRange
    val isNormal = !input.rs1.special && !expInSubnormalRange
    val fsm = new Area{
      val f2iShift = input.rs1.exponent - U(exponentOne)
      val isF2i = input.opcode === FpuOpcode.F2I
      val needRecoding = List(FpuOpcode.FMV_X_W, FpuOpcode.STORE).map(_ === input.opcode).orR && isSubnormal
      val done, boot = Reg(Bool())
      val isZero = input.rs1.isZero// || input.rs1.exponent < exponentOne-1

      val shift = new Area{
        val by = Reg(UInt(log2Up(p.internalMantissaSize+1 max 33) bits))
        val input = UInt(p.internalMantissaSize+1 max 33 bits).assignDontCare()
        var logic = input
        val scrap = Reg(Bool)
        for(i <- by.range){
          scrap setWhen(by(i) && logic(0, 1 << i bits) =/= 0)
          logic \= by(i) ? (logic |>> (BigInt(1) << i)) | logic
        }
        when(boot){
          scrap := False
        }
        val output = RegNextWhen(logic, !done)
      }

      shift.input := (U(!isZero) @@ input.rs1.mantissa) << (if(p.withDouble) 0 else 9)

      val formatShiftOffset = muxDouble[UInt](input.format)(exponentOne-1023+1)(exponentOne - (if(p.withDouble) (127+34) else (127-10)))
      when(input.valid && (needRecoding || isF2i) && !done){
        halt := True
        when(boot){
          when(isF2i){
            shift.by := ((U(exponentOne + 31) - input.rs1.exponent).min(U(33)) + (if(p.withDouble) 20 else 0)).resized //TODO merge
          } otherwise {
            shift.by := (formatShiftOffset - input.rs1.exponent).resized
          }
          boot := False
        } otherwise {
          done := True
        }
      }

      when(!input.isStall){
        done := False
        boot := True
      }
    }

    val mantissaForced = False
    val exponentForced = False
    val mantissaForcedValue = Bool().assignDontCare()
    val exponentForcedValue = Bool().assignDontCare()
    val cononicalForced = False


    when(input.rs1.special){
      switch(input.rs1.exponent(1 downto 0)){
        is(FpuFloat.ZERO){
          mantissaForced      := True
          exponentForced      := True
          mantissaForcedValue := False
          exponentForcedValue := False
        }
        is(FpuFloat.INFINITY){
          mantissaForced      := True
          exponentForced      := True
          mantissaForcedValue := False
          exponentForcedValue := True
        }
        is(FpuFloat.NAN){
          exponentForced      := True
          exponentForcedValue := True
          when(input.rs1.isCanonical){
            cononicalForced := True
            mantissaForced      := True
            mantissaForcedValue := False
          }
        }
      }
    }



    when(isSubnormal){
      exponentForced      := True
      exponentForcedValue := False
      recodedResult(0,23 bits) := fsm.shift.output(22 downto 0).asBits
      whenDouble(input.format){
        recodedResult(51 downto 23) := fsm.shift.output(51 downto 23).asBits
      }{}
    }
    when(mantissaForced){
      recodedResult(0,23 bits) := (default -> mantissaForcedValue)
      whenDouble(input.format){
        recodedResult(23, 52-23 bits) := (default -> mantissaForcedValue)
      }{}
    }
    when(exponentForced){
      whenDouble(input.format){
        recodedResult(52, 11 bits) := (default -> exponentForcedValue)
      }  {
        recodedResult(23, 8 bits) := (default -> exponentForcedValue)
      }
    }
    when(cononicalForced){
      whenDouble(input.format){
        recodedResult(63) := False
        recodedResult(51) := True
      }  {
        recodedResult(31) := False
        recodedResult(22) := True
      }
    }



    val f2i = new Area{ //Will not work for 64 bits float max value rounding
      val unsigned = fsm.shift.output(32 downto 0) >> 1
      val resign = input.arg(0) && input.rs1.sign
      val round = fsm.shift.output(0) ## fsm.shift.scrap
      val increment = input.roundMode.mux(
        FpuRoundMode.RNE -> (round(1) && (round(0) || unsigned(0))),
        FpuRoundMode.RTZ -> False,
        FpuRoundMode.RDN -> (round =/= 0 &&  input.rs1.sign),
        FpuRoundMode.RUP -> (round =/= 0 && !input.rs1.sign),
        FpuRoundMode.RMM -> (round(1))
      )
      val result = (Mux(resign, ~unsigned, unsigned) + (resign ^ increment).asUInt)
      val overflow  = (input.rs1.exponent > (input.arg(0) ? U(exponentOne+30) | U(exponentOne+31)) || input.rs1.isInfinity) && !input.rs1.sign || input.rs1.isNan
      val underflow = (input.rs1.exponent > U(exponentOne+31) || input.arg(0) && unsigned.msb && unsigned(30 downto 0) =/= 0 || !input.arg(0) && (unsigned =/= 0 || increment) || input.rs1.isInfinity) && input.rs1.sign
      val isZero = input.rs1.isZero
      when(isZero){
        result := 0
      } elsewhen(underflow || overflow) {
        val low = overflow
        val high = input.arg(0) ^ overflow
        result := (31 -> high, default -> low)
        flag.NV := input.valid && input.opcode === FpuOpcode.F2I && fsm.done && !isZero
      } otherwise {
        flag.NX := input.valid && input.opcode === FpuOpcode.F2I && fsm.done && round =/= 0
      }
    }

    val bothZero = input.rs1.isZero && input.rs2.isZero
    val rs1Equal = input.rs1 === input.rs2
    val rs1AbsSmaller = (input.rs1.exponent @@ input.rs1.mantissa) < (input.rs2.exponent @@ input.rs2.mantissa)
    rs1AbsSmaller.setWhen(input.rs2.isInfinity)
    rs1AbsSmaller.setWhen(input.rs1.isZero)
    rs1AbsSmaller.clearWhen(input.rs2.isZero)
    rs1AbsSmaller.clearWhen(input.rs1.isInfinity)
    rs1Equal setWhen(input.rs1.sign === input.rs2.sign && input.rs1.isInfinity && input.rs2.isInfinity)
    val rs1Smaller = (input.rs1.sign ## input.rs2.sign).mux(
      0 -> rs1AbsSmaller,
      1 -> False,
      2 -> True,
      3 -> (!rs1AbsSmaller && !rs1Equal)
    )


    val minMaxResult = ((rs1Smaller ^ input.arg(0)) && !input.rs1.isNan || input.rs2.isNan) ? input.rs1 | input.rs2
    when(input.rs1.isNan && input.rs2.isNan) { minMaxResult.setNanQuiet }
    val cmpResult = B(rs1Smaller && !bothZero && !input.arg(1) || (rs1Equal || bothZero) && !input.arg(0))
    when(input.rs1.isNan || input.rs2.isNan) { cmpResult := 0 }
    val sgnjResult = (input.rs1.sign && input.arg(1)) ^ input.rs2.sign ^ input.arg(0)
    val fclassResult = B(0, 32 bits)
    val decoded = input.rs1.decode()
    fclassResult(0) :=  input.rs1.sign &&  decoded.isInfinity
    fclassResult(1) :=  input.rs1.sign &&  isNormal
    fclassResult(2) :=  input.rs1.sign &&  isSubnormal
    fclassResult(3) :=  input.rs1.sign &&  decoded.isZero
    fclassResult(4) := !input.rs1.sign &&  decoded.isZero
    fclassResult(5) := !input.rs1.sign &&  isSubnormal
    fclassResult(6) := !input.rs1.sign &&  isNormal
    fclassResult(7) := !input.rs1.sign &&  decoded.isInfinity
    fclassResult(8) :=   decoded.isNan && !decoded.isQuiet
    fclassResult(9) :=   decoded.isNan &&  decoded.isQuiet


    switch(input.opcode){
      is(FpuOpcode.STORE)   { result := recodedResult }
      is(FpuOpcode.FMV_X_W) { result := recodedResult }
      is(FpuOpcode.F2I)     { result(31 downto 0) := f2i.result.asBits }
      is(FpuOpcode.CMP)     { result(31 downto 0) := cmpResult.resized }
      is(FpuOpcode.FCLASS)  { result(31 downto 0) := fclassResult.resized }
    }

    val toFpuRf = List(FpuOpcode.MIN_MAX, FpuOpcode.SGNJ).map(input.opcode === _).orR

    rfOutput.valid := input.valid && toFpuRf && !halt
    rfOutput.source := input.source
    rfOutput.lockId := input.lockId
    rfOutput.rd := input.rd
    rfOutput.roundMode := input.roundMode
    if(p.withDouble) rfOutput.format := input.format
    rfOutput.scrap := False
    rfOutput.value.assignDontCare()
    switch(input.opcode){
      is(FpuOpcode.MIN_MAX){
        rfOutput.value.sign     := minMaxResult.sign
        rfOutput.value.exponent := minMaxResult.exponent
        rfOutput.value.mantissa := minMaxResult.mantissa @@ U"0"
        rfOutput.value.special  := minMaxResult.special
      }
      is(FpuOpcode.SGNJ){
        rfOutput.value.sign     := sgnjResult
        rfOutput.value.exponent := input.rs1.exponent
        rfOutput.value.mantissa := input.rs1.mantissa @@ U"0"
        rfOutput.value.special  := input.rs1.special
      }
    }

    val signalQuiet = input.opcode === FpuOpcode.CMP && input.arg =/= 2
    val rs1Nan = input.rs1.isNan
    val rs2Nan = input.rs2.isNan
    val rs1NanNv = input.rs1.isNan && (!input.rs1.isQuiet || signalQuiet)
    val rs2NanNv = input.rs2.isNan && (!input.rs2.isQuiet || signalQuiet)
    val nv = (input.opcode === FpuOpcode.CMP || input.opcode === FpuOpcode.MIN_MAX) && (rs1NanNv || rs2NanNv)
    flag.NV setWhen(input.valid && nv)

    input.ready := !halt && (toFpuRf ? rfOutput.ready | io.port.map(_.rsp.ready).read(input.source))
    for(i <- 0 until portCount){
      def rsp = io.port(i).rsp
      rsp.valid := input.valid && input.source === i && !toFpuRf && !halt
      rsp.value := result
      completion(i).increments += (RegNext(rsp.fire) init(False))
    }
  }

  val mul = p.withMul generate new Area{
    val input = decode.mul.stage()

    val math = new Area {
      val mulA = U(input.msb1) @@ input.rs1.mantissa
      val mulB = U(input.msb2) @@ input.rs2.mantissa
      val mulC = mulA * mulB
      val exp = input.rs1.exponent +^ input.rs2.exponent
    }

    val norm = new Area{
      val (mulHigh, mulLow) = math.mulC.splitAt(p.internalMantissaSize-1)
      val scrap = mulLow =/= 0
      val needShift = mulHigh.msb
      val exp = math.exp + U(needShift)
      val man = needShift ? mulHigh(1, p.internalMantissaSize+1 bits) | mulHigh(0, p.internalMantissaSize+1 bits)
      scrap setWhen(needShift && mulHigh(0))
      val forceZero = input.rs1.isZero || input.rs2.isZero
      val underflowThreshold = muxDouble[UInt](input.format)(exponentOne + exponentOne - 1023 - 53) (exponentOne + exponentOne - 127 - 24)
      val underflowExp = muxDouble[UInt](input.format)(exponentOne - 1023 - 54) (exponentOne - 127 - 25)
      val forceUnderflow = exp <  underflowThreshold
      val forceOverflow = input.rs1.isInfinity || input.rs2.isInfinity
      val infinitynan = ((input.rs1.isInfinity || input.rs2.isInfinity) && (input.rs1.isZero || input.rs2.isZero))
      val forceNan = input.rs1.isNan || input.rs2.isNan || infinitynan

      val output = p.writeFloating()
      output.sign := input.rs1.sign ^ input.rs2.sign
      output.exponent := (exp - exponentOne).resized
      output.mantissa := man.asUInt
      output.setNormal

      when(exp(exp.getWidth-3, 3 bits) >= 5) { output.exponent(p.internalExponentSize-2, 2 bits) := 3 }

      val flag = io.port(input.source).completion.flag
      when(forceNan) {
        output.setNanQuiet
        flag.NV setWhen(input.valid && (infinitynan || input.rs1.isNanSignaling || input.rs2.isNanSignaling))
      } elsewhen(forceOverflow) {
        output.setInfinity
      } elsewhen(forceZero) {
        output.setZero
      } elsewhen(forceUnderflow) {
        output.exponent := underflowExp.resized
      }

    }

    val notMul = new Area{
      val output = Flow(UInt(p.internalMantissaSize + 1 bits))
      output.valid := input.valid && input.divSqrt
      output.payload := math.mulC(p.internalMantissaSize, p.internalMantissaSize+1 bits)
    }

    val output = Stream(MergeInput())
    output.valid  := input.valid && !input.add && !input.divSqrt
    output.source := input.source
    output.lockId := input.lockId
    output.rd     := input.rd
    if(p.withDouble) output.format := input.format
    output.roundMode := input.roundMode
    output.scrap  := norm.scrap
    output.value  := norm.output

    decode.mulToAdd.valid := input.valid && input.add
    decode.mulToAdd.source := input.source
    decode.mulToAdd.rs1.mantissa := norm.output.mantissa >> 1 //FMA Precision lost
    decode.mulToAdd.rs1.exponent := norm.output.exponent
    decode.mulToAdd.rs1.sign := norm.output.sign
    decode.mulToAdd.rs1.special := False //TODO
    decode.mulToAdd.rs2 := input.rs3
    decode.mulToAdd.rd := input.rd
    decode.mulToAdd.lockId := input.lockId
    decode.mulToAdd.roundMode := input.roundMode
    if(p.withDouble) decode.mulToAdd.format := input.format

    input.ready := (input.add ? decode.mulToAdd.ready | output.ready) || input.divSqrt
  }

  val divSqrt = p.withDivSqrt generate new Area {
    val input = decode.divSqrt.stage()

    val aproxWidth = 8
    val aproxDepth = 64
    val divIterationCount = 3
    val sqrtIterationCount = 3

    val mulWidth = p.internalMantissaSize + 1

    import FpuDivSqrtIterationState._
    val state     = RegInit(FpuDivSqrtIterationState.IDLE())
    val iteration = Reg(UInt(log2Up(divIterationCount max sqrtIterationCount) bits))

    decode.divSqrtToMul.valid := False
    decode.divSqrtToMul.source := input.source
    decode.divSqrtToMul.rs1.assignDontCare()
    decode.divSqrtToMul.rs2.assignDontCare()
    decode.divSqrtToMul.rs3.assignDontCare()
    decode.divSqrtToMul.rd := input.rd
    decode.divSqrtToMul.lockId := input.lockId
    decode.divSqrtToMul.add := False
    decode.divSqrtToMul.divSqrt := True
    decode.divSqrtToMul.msb1 := True
    decode.divSqrtToMul.msb2 := True
    decode.divSqrtToMul.rs1.special := False //TODO
    decode.divSqrtToMul.rs2.special := False
    decode.divSqrtToMul.roundMode := input.roundMode
    if(p.withDouble) decode.divSqrtToMul.format := input.format


    val aprox = new Area {
      val rom = Mem(UInt(aproxWidth bits), aproxDepth * 2)
      val divTable, sqrtTable = ArrayBuffer[Double]()
      for(i <- 0 until aproxDepth){
        val value = 1+(i+0.5)/aproxDepth
        divTable += 1/value
      }
      for(i <- 0 until aproxDepth){
        val scale = if(i < aproxDepth/2) 2 else 1
        val value = scale+(scale*(i%(aproxDepth/2)+0.5)/aproxDepth*2)
//        println(s"$i => $value" )
        sqrtTable += 1/Math.sqrt(value)
      }
      val romElaboration = (sqrtTable ++ divTable).map(v => BigInt(((v-0.5)*2*(1 << aproxWidth)).round))

      rom.initBigInt(romElaboration)
      val div = input.rs2.mantissa.takeHigh(log2Up(aproxDepth))
      val sqrt = U(input.rs1.exponent.lsb ## input.rs1.mantissa).takeHigh(log2Up(aproxDepth))
      val address = U(input.div ## (input.div ? div | sqrt))
      val raw = rom.readAsync(address)
      val result = U"01" @@ (raw << (mulWidth-aproxWidth-2))
    }

    val divExp = new Area{
      val value = (1 << p.internalExponentSize) - 3 - input.rs2.exponent
    }
    val sqrtExp = new Area{
      val value = ((1 << p.internalExponentSize-1) + (1 << p.internalExponentSize-2) - 2 -1) - (input.rs1.exponent >> 1) + U(!input.rs1.exponent.lsb)
    }

    def mulArg(rs1 : UInt, rs2 : UInt): Unit ={
      decode.divSqrtToMul.rs1.mantissa := rs1.resized
      decode.divSqrtToMul.rs2.mantissa := rs2.resized
      decode.divSqrtToMul.msb1 := rs1.msb
      decode.divSqrtToMul.msb2 := rs2.msb
    }

    val mulBuffer = mul.notMul.output.toStream.stage
    mulBuffer.ready := False

    val iterationValue = Reg(UInt(mulWidth bits))

    input.ready := False
    switch(state){
      is(IDLE){
        iterationValue := aprox.result
        iteration := 0
        when(input.valid) {
          state := YY
        }
      }
      is(YY){
        decode.divSqrtToMul.valid := True
        mulArg(iterationValue, iterationValue)
        when(decode.divSqrtToMul.ready) {
          state := XYY
        }
      }
      is(XYY){
        decode.divSqrtToMul.valid := mulBuffer.valid
        val sqrtIn = !input.rs1.exponent.lsb ? (U"1" @@ input.rs1.mantissa) | ((U"1" @@ input.rs1.mantissa) |>> 1)
        val divIn = U"1" @@ input.rs2.mantissa
        mulArg(input.div ? divIn| sqrtIn, mulBuffer.payload)
        when(mulBuffer.valid && decode.divSqrtToMul.ready) {
          state := (input.div ? Y2_XYY | _15_XYY2)
          mulBuffer.ready := True
        }
      }
      is(Y2_XYY){
        mulBuffer.ready := True
        when(mulBuffer.valid) {
          iterationValue := ((iterationValue << 1) - mulBuffer.payload).resized
          mulBuffer.ready := True
          iteration := iteration + 1
          when(iteration =/= divIterationCount-1){ //TODO
            state := YY
          } otherwise {
            state := DIV
          }
        }
      }
      is(DIV){
        decode.divSqrtToMul.valid := True
        decode.divSqrtToMul.divSqrt := False
        decode.divSqrtToMul.rs1 := input.rs1
        decode.divSqrtToMul.rs2.sign := input.rs2.sign
        decode.divSqrtToMul.rs2.exponent := divExp.value + iterationValue.msb.asUInt
        decode.divSqrtToMul.rs2.mantissa := (iterationValue << 1).resized
        val zero = input.rs2.isInfinity
        val overflow = input.rs2.isZero
        val nan = input.rs2.isNan || (input.rs1.isZero && input.rs2.isZero)

        when(nan){
          decode.divSqrtToMul.rs2.setNanQuiet
        } elsewhen(overflow) {
          decode.divSqrtToMul.rs2.setInfinity
        } elsewhen(zero) {
          decode.divSqrtToMul.rs2.setZero
        }
        when(decode.divSqrtToMul.ready) {
          state := IDLE
          input.ready := True
        }
      }
      is(_15_XYY2){
        when(mulBuffer.valid) {
          state := Y_15_XYY2
          mulBuffer.payload.getDrivingReg := (U"11" << mulWidth-2) - (mulBuffer.payload)
        }
      }
      is(Y_15_XYY2){
        decode.divSqrtToMul.valid := True
        mulArg(iterationValue, mulBuffer.payload)
        when(decode.divSqrtToMul.ready) {
          mulBuffer.ready := True
          state := Y_15_XYY2_RESULT
        }
      }
      is(Y_15_XYY2_RESULT){
        iterationValue := mulBuffer.payload
        mulBuffer.ready := True
        when(mulBuffer.valid) {
          iteration := iteration + 1
          when(iteration =/= sqrtIterationCount-1){
            state := YY
          } otherwise {
            state := SQRT
          }
        }
      }
      is(SQRT){
        decode.divSqrtToMul.valid := True
        decode.divSqrtToMul.divSqrt := False
        decode.divSqrtToMul.rs1 := input.rs1
        decode.divSqrtToMul.rs2.sign := False
        decode.divSqrtToMul.rs2.exponent := sqrtExp.value + iterationValue.msb.asUInt
        decode.divSqrtToMul.rs2.mantissa := (iterationValue << 1).resized

        val nan       = input.rs1.sign && !input.rs1.isZero

        when(nan){
          decode.divSqrtToMul.rs2.setNanQuiet
        }

        when(decode.divSqrtToMul.ready) {
          state := IDLE
          input.ready := True
        }
      }
    }
  }

  val add = p.withAdd generate new Area{
    val input = decode.add.stage()

    val shifter = new Area {
      val exp21 = input.rs2.exponent -^ input.rs1.exponent
      val rs1ExponentBigger = (exp21.msb || input.rs2.isZero) && !input.rs1.isZero
      val rs1ExponentEqual = input.rs1.exponent === input.rs2.exponent
      val rs1MantissaBigger = input.rs1.mantissa > input.rs2.mantissa
      val absRs1Bigger = ((rs1ExponentBigger || rs1ExponentEqual && rs1MantissaBigger) && !input.rs1.isZero || input.rs1.isInfinity) && !input.rs2.isInfinity
      val shiftBy = rs1ExponentBigger ? (0-exp21) | exp21
      val shiftOverflow = (shiftBy >= p.internalMantissaSize+3)
      val passThrough = shiftOverflow || (input.rs1.isZero) || (input.rs2.isZero)

      //Note that rs1ExponentBigger can be replaced by absRs1Bigger bellow to avoid xsigned two complement in math block at expense of combinatorial path
      val xySign = absRs1Bigger ? input.rs1.sign | input.rs2.sign
      val xSign = xySign ^ (rs1ExponentBigger ? input.rs1.sign | input.rs2.sign)
      val ySign = xySign ^ (rs1ExponentBigger ? input.rs2.sign | input.rs1.sign)
      val xMantissa = U"1" @@ (rs1ExponentBigger ? input.rs1.mantissa | input.rs2.mantissa) @@ U"00"
      val yMantissaUnshifted = U"1" @@ (rs1ExponentBigger ? input.rs2.mantissa | input.rs1.mantissa) @@ U"00"
      var yMantissa = CombInit(yMantissaUnshifted)
      val roundingScrap = CombInit(shiftOverflow)
      for(i <- 0 until log2Up(p.internalMantissaSize)){
        roundingScrap setWhen(shiftBy(i) && yMantissa(0, 1 << i bits) =/= 0)
        yMantissa \= shiftBy(i) ? (yMantissa |>> (BigInt(1) << i)) | yMantissa
      }
      when(passThrough) { yMantissa := 0 }
      when(shiftOverflow) { roundingScrap := True }
      when(input.rs1.special || input.rs2.special){ roundingScrap := False }
      val xyExponent = rs1ExponentBigger ? input.rs1.exponent | input.rs2.exponent
    }

    val math = new Area {
      def xSign = shifter.xSign
      def ySign = shifter.ySign
      def xMantissa = shifter.xMantissa
      def yMantissa = shifter.yMantissa
      def xyExponent = shifter.xyExponent
      def xySign = shifter.xySign

      val xSigned = xMantissa.twoComplement(xSign) //TODO Is that necessary ?
      val ySigned = ((ySign ## Mux(ySign, ~yMantissa, yMantissa)).asUInt + (ySign && !shifter.roundingScrap).asUInt).asSInt //rounding here
      val xyMantissa = U(xSigned +^ ySigned).trim(1 bits)
    }

    val norm = new Area{
      def xyExponent = math.xyExponent
      def xyMantissa = math.xyMantissa
      val xySign = CombInit(math.xySign)

      val shiftOh = OHMasking.first(xyMantissa.asBools.reverse)
      val shift = OHToUInt(shiftOh)
      val mantissa = (xyMantissa |<< shift)
      val exponent = xyExponent -^ shift + 1
      val forceZero = xyMantissa === 0 || (input.rs1.isZero && input.rs2.isZero)
//      val forceOverflow = exponent === exponentOne + 128  //Handled by writeback rounding
      val forceInfinity = (input.rs1.isInfinity || input.rs2.isInfinity)
      val infinityNan =  (input.rs1.isInfinity && input.rs2.isInfinity && (input.rs1.sign ^ input.rs2.sign))
      val forceNan = input.rs1.isNan || input.rs2.isNan || infinityNan
    }


    val output = input.swapPayload(MergeInput())
    output.source := input.source
    output.lockId := input.lockId
    output.rd     := input.rd
    output.value.sign := norm.xySign
    output.value.mantissa := (norm.mantissa >> 2).resized
    output.value.exponent := norm.exponent.resized
    output.value.special := False
    output.roundMode := input.roundMode
    if(p.withDouble) output.format := input.format
    output.scrap := (norm.mantissa(1) | norm.mantissa(0) | shifter.roundingScrap)


    val flag = io.port(input.source).completion.flag
    flag.NV setWhen(input.valid && (norm.infinityNan || input.rs1.isNanSignaling || input.rs2.isNanSignaling))
    when(norm.forceNan) {
      output.value.setNanQuiet
    } elsewhen(norm.forceZero) {
      output.value.setZero
      when(norm.xyMantissa === 0 || input.rs1.isZero && input.rs2.isZero){
        output.value.sign := input.rs1.sign && input.rs2.sign
      }
      when((input.rs1.sign || input.rs2.sign) && input.roundMode === FpuRoundMode.RDN){
        output.value.sign := True
      }
    } elsewhen(norm.forceInfinity) {
      output.value.setInfinity
    }
  }


  val merge = new Area {
    //TODO maybe load can bypass merge and round.
    val inputs = ArrayBuffer[Stream[MergeInput]]()
    inputs += load.s1.output
    if(p.withAdd) (inputs += add.output)
    if(p.withMul) (inputs += mul.output)
    if(p.withShortPipMisc) (inputs += shortPip.rfOutput)
    val arbitrated = StreamArbiterFactory.lowerFirst.noLock.on(inputs)
    val isCommited = rf.lock.map(_.commited).read(arbitrated.lockId)
    val commited = arbitrated.haltWhen(!isCommited).toFlow
  }

  val round = new Area{
    val input = merge.commited.combStage

    val manAggregate = input.value.mantissa @@ input.scrap
    val expBase = muxDouble[UInt](input.format)(exponentF64Subnormal+1)(exponentF32Subnormal+1)
    val expDif = expBase -^ input.value.exponent
    val expSubnormal = !expDif.msb
    var discardCount = (expSubnormal ? expDif.resize(log2Up(p.internalMantissaSize) bits) |  U(0))
    if(p.withDouble) when(input.format === FpuFormat.FLOAT){
      discardCount \= discardCount + 29
    }
    val exactMask = (List(True) ++ (0 until p.internalMantissaSize+1).map(_ < discardCount)).asBits.asUInt
    val roundAdjusted = (True ## (manAggregate>>1))(discardCount) ## ((manAggregate & exactMask) =/= 0)

    val mantissaIncrement = !input.value.special && input.roundMode.mux(
      FpuRoundMode.RNE -> (roundAdjusted(1) && (roundAdjusted(0) || (U"01" ## (manAggregate>>2))(discardCount))),
      FpuRoundMode.RTZ -> False,
      FpuRoundMode.RDN -> (roundAdjusted =/= 0 &&  input.value.sign),
      FpuRoundMode.RUP -> (roundAdjusted =/= 0 && !input.value.sign),
      FpuRoundMode.RMM -> (roundAdjusted(1))
    )

    val math = p.internalFloating()
    val mantissaRange = p.internalMantissaSize downto 1
    val adderMantissa = input.value.mantissa(mantissaRange) & (mantissaIncrement ? ~(exactMask.trim(1) >> 1) | input.value.mantissa(mantissaRange).maxValue)
    val adderRightOp = (mantissaIncrement ? (exactMask >> 1)| U(0)).resize(p.internalMantissaSize bits)
    val adder = (input.value.exponent @@ adderMantissa) + adderRightOp + U(mantissaIncrement)
    math.special := input.value.special
    math.sign := input.value.sign
    math.exponent := adder(p.internalMantissaSize, p.internalExponentSize bits)
    math.mantissa := adder(0, p.internalMantissaSize bits)

    val patched = CombInit(math)
    val nx,of,uf = False
//    val ufPatch = input.roundMode === FpuRoundMode.RUP && !input.value.sign && !input.scrap|| input.roundMode === FpuRoundMode.RDN && input.value.sign && !input.scrap
//    when(!math.special && (input.value.exponent <= exponentOne-127 && (math.exponent =/= exponentOne-126 || !input.value.mantissa.lsb || ufPatch)) && roundAdjusted.asUInt =/= 0){
//      uf := True
//    }



    val ufSubnormalThreshold = muxDouble[UInt](input.format)(exponentF64Subnormal)(exponentF32Subnormal)
    val ufThreshold = muxDouble[UInt](input.format)(exponentF64Subnormal-52+1)(exponentF32Subnormal-23+1)
    val ofThreshold = muxDouble[UInt](input.format)(exponentF64Infinity-1)(exponentF32Infinity-1)

    when(!math.special && math.exponent <= ufSubnormalThreshold && roundAdjusted.asUInt =/= 0){ //Do not catch exact 1.17549435E-38 underflow, but, who realy care ?
      uf := True
    }
    when(!math.special && math.exponent > ofThreshold){
      nx := True
      of := True
      val doMax = input.roundMode.mux(
        FpuRoundMode.RNE -> (False),
        FpuRoundMode.RTZ -> (True),
        FpuRoundMode.RDN -> (!math.sign),
        FpuRoundMode.RUP -> (math.sign),
        FpuRoundMode.RMM -> (False)
      )
      when(doMax){
        patched.exponent := ofThreshold
        patched.mantissa.setAll()
      } otherwise {
        patched.setInfinity
      }
    }


    when(!math.special && math.exponent < ufThreshold){
      nx := True
      uf := True
      val doMin = input.roundMode.mux(
        FpuRoundMode.RNE -> (False),
        FpuRoundMode.RTZ -> (False),
        FpuRoundMode.RDN -> (math.sign),
        FpuRoundMode.RUP -> (!math.sign),
        FpuRoundMode.RMM -> (False)
      )
      when(doMin){
        patched.exponent := ufThreshold.resized
        patched.mantissa := 0
      } otherwise {
        patched.setZero
      }
    }


    nx setWhen(!input.value.special && (roundAdjusted =/= 0))
    when(input.valid){
      val flag = io.port(input.source).completion.flag
      flag.NX setWhen(nx)
      flag.OF setWhen(of)
      flag.UF setWhen(uf)
    }
    val output = input.swapPayload(RoundOutput())
    output.source := input.source
    output.lockId := input.lockId
    output.rd := input.rd
    if(p.withDouble) output.format := input.format
    output.value := patched
  }

  val writeback = new Area{
    val input = round.output.combStage

    for(i <- 0 until portCount){
      completion(i).increments += (RegNext(input.fire && input.source === i) init(False))
    }

    when(input.valid){
      for(i <- 0 until rfLockCount) when(input.lockId === i){
        rf.lock(i).valid := False
      }
    }

    val port = rf.ram.writePort
    port.valid := input.valid && rf.lock.map(_.write).read(input.lockId)
    port.address := input.source @@ input.rd
    port.data.value := input.value
    if(p.withDouble) port.data.boxed := input.format === FpuFormat.FLOAT

    val randomSim = p.sim generate (in UInt(p.internalMantissaSize bits))
    if(p.sim) when(port.data.value.isZero || port.data.value.isInfinity){
      port.data.value.mantissa := randomSim
    }
    if(p.sim) when(input.value.special){
      port.data.value.exponent(p.internalExponentSize-1 downto 3) := randomSim.resized
      when(!input.value.isNan){
        port.data.value.exponent(2 downto 2) := randomSim.resized
      }
    }

    when(port.valid){
      assert(!(port.data.value.exponent === 0 && !port.data.value.special), "Special violation")
      assert(!(port.data.value.exponent === port.data.value.exponent.maxValue && !port.data.value.special), "Special violation")
    }
  }
}




object FpuSynthesisBench extends App{
  val payloadType = HardType(Bits(8 bits))
  class Fpu(name : String, portCount : Int, p : FpuParameter) extends Rtl{
    override def getName(): String = "Fpu_" + name
    override def getRtlPath(): String = getName() + ".v"
    SpinalVerilog(new FpuCore(portCount, p){

      setDefinitionName(Fpu.this.getName())
    })
  }

  class Shifter(width : Int) extends Rtl{
    override def getName(): String = "shifter_" + width
    override def getRtlPath(): String = getName() + ".v"
    SpinalVerilog(new Component{
      val a = in UInt(width bits)
      val sel = in UInt(log2Up(width) bits)
      val result = out(a >> sel)
      setDefinitionName(Shifter.this.getName())
    })
  }

  class Rotate(width : Int) extends Rtl{
    override def getName(): String = "rotate_" + width
    override def getRtlPath(): String = getName() + ".v"
    SpinalVerilog(new Component{
      val a = in UInt(width bits)
      val sel = in UInt(log2Up(width) bits)
      val result = out(Delay(Delay(a,3).rotateLeft(Delay(sel,3)),3))
      setDefinitionName(Rotate.this.getName())
    })
  }

//    rotate2_24 ->
//    Artix 7 -> 233 Mhz 96 LUT 167 FF
//  Artix 7 -> 420 Mhz 86 LUT 229 FF
//  rotate2_32 ->
//    Artix 7 -> 222 Mhz 108 LUT 238 FF
//  Artix 7 -> 399 Mhz 110 LUT 300 FF
//  rotate2_52 ->
//    Artix 7 -> 195 Mhz 230 LUT 362 FF
//  Artix 7 -> 366 Mhz 225 LUT 486 FF
//  rotate2_64 ->
//    Artix 7 -> 182 Mhz 257 LUT 465 FF
//  Artix 7 -> 359 Mhz 266 LUT 591 FF
  class Rotate2(width : Int) extends Rtl{
    override def getName(): String = "rotate2_" + width
    override def getRtlPath(): String = getName() + ".v"
    SpinalVerilog(new Component{
      val a = in UInt(width bits)
      val sel = in UInt(log2Up(width) bits)
      val result = out(Delay((U(0, width bits) @@ Delay(a,3)).rotateLeft(Delay(sel,3)),3))
      setDefinitionName(Rotate2.this.getName())
    })
  }

  class Rotate3(width : Int) extends Rtl{
    override def getName(): String = "rotate3_" + width
    override def getRtlPath(): String = getName() + ".v"
    SpinalVerilog(new Component{
      val a = Delay(in UInt(width bits), 3)
      val sel = Delay(in UInt(log2Up(width) bits),3)
//      val result =
//      val output = Delay(result, 3)
      setDefinitionName(Rotate3.this.getName())
    })
  }


  val rtls = ArrayBuffer[Rtl]()
  rtls += new Fpu(
    "32",
    portCount = 1,
    FpuParameter(
      withDouble = false
    )
  )
  rtls += new Fpu(
    "64",
    portCount = 1,
    FpuParameter(
      withDouble = true
    )
  )

//  rtls += new Shifter(24)
//  rtls += new Shifter(32)
//  rtls += new Shifter(52)
//  rtls += new Shifter(64)
//  rtls += new Rotate(24)
//  rtls += new Rotate(32)
//  rtls += new Rotate(52)
//  rtls += new Rotate(64)
//  rtls += new Rotate3(24)
//  rtls += new Rotate3(32)
//  rtls += new Rotate3(52)
//  rtls += new Rotate3(64)

  val targets = XilinxStdTargets()// ++ AlteraStdTargets()


  Bench(rtls, targets)
}