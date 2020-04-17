package vexriscv.demo.smp

import spinal.core
import spinal.core._
import spinal.core.sim.{onSimEnd, simSuccess}
import spinal.lib._
import spinal.lib.bus.bmb.sim.BmbMemoryAgent
import spinal.lib.bus.bmb.{Bmb, BmbArbiter, BmbDecoder, BmbExclusiveMonitor, BmbInvalidateMonitor, BmbParameter}
import spinal.lib.com.jtag.Jtag
import spinal.lib.com.jtag.sim.JtagTcp
import vexriscv.demo.smp.VexRiscvSmpClusterTest.{cpuCount, withStall}
import vexriscv.ip.{DataCacheAck, DataCacheConfig, DataCacheMemBus, InstructionCacheConfig}
import vexriscv.plugin.{BranchPlugin, CsrPlugin, CsrPluginConfig, DBusCachedPlugin, DBusSimplePlugin, DebugPlugin, DecoderSimplePlugin, FullBarrelShifterPlugin, HazardSimplePlugin, IBusCachedPlugin, IBusSimplePlugin, IntAluPlugin, MmuPlugin, MmuPortConfig, MulDivIterativePlugin, MulPlugin, RegFilePlugin, STATIC, SrcPlugin, YamlPlugin}
import vexriscv.{Riscv, VexRiscv, VexRiscvConfig, plugin}

import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer


case class VexRiscvSmpClusterParameter( cpuConfigs : Seq[VexRiscvConfig])

case class VexRiscvSmpCluster(p : VexRiscvSmpClusterParameter,
                              debugClockDomain : ClockDomain) extends Component{
  val dBusParameter = p.cpuConfigs.head.plugins.find(_.isInstanceOf[DBusCachedPlugin]).get.asInstanceOf[DBusCachedPlugin].config.getBmbParameter()
  val dBusArbiterParameter = dBusParameter.copy(sourceWidth = log2Up(p.cpuConfigs.size))
  val exclusiveMonitorParameter = dBusArbiterParameter
  val invalidateMonitorParameter = BmbExclusiveMonitor.outputParameter(exclusiveMonitorParameter)
  val dMemParameter = BmbInvalidateMonitor.outputParameter(invalidateMonitorParameter)

  val iBusParameter = p.cpuConfigs.head.plugins.find(_.isInstanceOf[IBusCachedPlugin]).get.asInstanceOf[IBusCachedPlugin].config.getBmbParameter()
  val iBusArbiterParameter = iBusParameter.copy(sourceWidth = log2Up(p.cpuConfigs.size))
  val iMemParameter = iBusArbiterParameter

  val io = new Bundle {
    val dMem = master(Bmb(dMemParameter))
//    val iMem = master(Bmb(iMemParameter))
    val iMems = Vec(master(Bmb(iMemParameter)), p.cpuConfigs.size)
    val timerInterrupts = in Bits(p.cpuConfigs.size bits)
    val externalInterrupts = in Bits(p.cpuConfigs.size bits)
    val softwareInterrupts = in Bits(p.cpuConfigs.size bits)
    val externalSupervisorInterrupts = in Bits(p.cpuConfigs.size bits)
    val jtag = slave(Jtag())
    val debugReset = out Bool()
  }

  val cpus = for((cpuConfig, cpuId) <- p.cpuConfigs.zipWithIndex) yield new Area{
    var iBus : Bmb = null
    var dBus : Bmb = null
    cpuConfig.plugins.foreach {
      case plugin: DebugPlugin => debugClockDomain{
        plugin.debugClockDomain = debugClockDomain
      }
      case _ =>
    }
    val core = new VexRiscv(cpuConfig)
    core.plugins.foreach {
      case plugin: IBusCachedPlugin => iBus = plugin.iBus.toBmb()
      case plugin: DBusCachedPlugin => dBus = plugin.dBus.toBmb()
      case plugin: CsrPlugin => {
        plugin.softwareInterrupt := io.softwareInterrupts(cpuId)
        plugin.externalInterrupt := io.externalInterrupts(cpuId)
        plugin.timerInterrupt := io.timerInterrupts(cpuId)
        if (plugin.config.supervisorGen) plugin.externalInterruptS := io.externalSupervisorInterrupts(cpuId)
      }
      case plugin: DebugPlugin => debugClockDomain{
        io.debugReset := RegNext(plugin.io.resetOut)
        io.jtag <> plugin.io.bus.fromJtag()
      }
      case _ =>
    }
  }

  val dBusArbiter = BmbArbiter(
    p = dBusArbiterParameter,
    portCount = cpus.size,
    pendingRspMax = 64,
    lowerFirstPriority = false,
    inputsWithInv = cpus.map(_ => true),
    inputsWithSync = cpus.map(_ => true),
    pendingInvMax = 16
  )

  (dBusArbiter.io.inputs, cpus).zipped.foreach(_ << _.dBus)

  val exclusiveMonitor = BmbExclusiveMonitor(
    inputParameter = exclusiveMonitorParameter,
    pendingWriteMax = 64
  )
  exclusiveMonitor.io.input << dBusArbiter.io.output

  val invalidateMonitor = BmbInvalidateMonitor(
    inputParameter = invalidateMonitorParameter,
    pendingInvMax = 16
  )
  invalidateMonitor.io.input << exclusiveMonitor.io.output

  io.dMem << invalidateMonitor.io.output

//  val iBusArbiter = BmbArbiter(
//    p = iBusArbiterParameter,
//    portCount = cpus.size,
//    pendingRspMax = 64,
//    lowerFirstPriority = false,
//    inputsWithInv = cpus.map(_ => true),
//    inputsWithSync = cpus.map(_ => true),
//    pendingInvMax = 16
//  )
//
//  (iBusArbiter.io.inputs, cpus).zipped.foreach(_ << _.iBus)
//  io.iMem << iBusArbiter.io.output
  (io.iMems, cpus).zipped.foreach(_ << _.iBus)
}



object VexRiscvSmpClusterGen {
  def vexRiscvConfig(id : Int) = {
    val config = VexRiscvConfig(
      plugins = List(
        new MmuPlugin(
          ioRange = x => x(31 downto 28) === 0xF
        ),
        //Uncomment the whole IBusSimplePlugin and comment IBusCachedPlugin if you want uncached iBus config
        //        new IBusSimplePlugin(
        //          resetVector = 0x80000000l,
        //          cmdForkOnSecondStage = false,
        //          cmdForkPersistence = false,
        //          prediction = DYNAMIC_TARGET,
        //          historyRamSizeLog2 = 10,
        //          catchAccessFault = true,
        //          compressedGen = true,
        //          busLatencyMin = 1,
        //          injectorStage = true,
        //          memoryTranslatorPortConfig = withMmu generate MmuPortConfig(
        //            portTlbSize = 4
        //          )
        //        ),

        //Uncomment the whole IBusCachedPlugin and comment IBusSimplePlugin if you want cached iBus config
        new IBusCachedPlugin(
          resetVector = 0x80000000l,
          compressedGen = false,
          prediction = STATIC,
          injectorStage = false,
          config = InstructionCacheConfig(
            cacheSize = 4096*1,
            bytePerLine = 32,
            wayCount = 1,
            addressWidth = 32,
            cpuDataWidth = 32,
            memDataWidth = 32,
            catchIllegalAccess = true,
            catchAccessFault = true,
            asyncTagMemory = false,
            twoCycleRam = false,
            twoCycleCache = true
            //          )
          ),
          memoryTranslatorPortConfig = MmuPortConfig(
            portTlbSize = 4
          )
        ),
        //          ).newTightlyCoupledPort(TightlyCoupledPortParameter("iBusTc", a => a(30 downto 28) === 0x0 && a(5))),
        //        new DBusSimplePlugin(
        //          catchAddressMisaligned = true,
        //          catchAccessFault = true,
        //          earlyInjection = false,
        //          withLrSc = true,
        //          memoryTranslatorPortConfig = withMmu generate MmuPortConfig(
        //            portTlbSize = 4
        //          )
        //        ),
        new DBusCachedPlugin(
          dBusCmdMasterPipe = true,
          dBusCmdSlavePipe = true,
          dBusRspSlavePipe = true,
          config = new DataCacheConfig(
            cacheSize         = 4096*1,
            bytePerLine       = 32,
            wayCount          = 1,
            addressWidth      = 32,
            cpuDataWidth      = 32,
            memDataWidth      = 32,
            catchAccessError  = true,
            catchIllegal      = true,
            catchUnaligned    = true,
            withLrSc = true,
            withAmo = true,
            withExclusive = true,
            withInvalidate = true
            //          )
          ),
          memoryTranslatorPortConfig = MmuPortConfig(
            portTlbSize = 4
          )
        ),

        //          new MemoryTranslatorPlugin(
        //            tlbSize = 32,
        //            virtualRange = _(31 downto 28) === 0xC,
        //            ioRange      = _(31 downto 28) === 0xF
        //          ),

        new DecoderSimplePlugin(
          catchIllegalInstruction = true
        ),
        new RegFilePlugin(
          regFileReadyKind = plugin.SYNC,
          zeroBoot = true
        ),
        new IntAluPlugin,
        new SrcPlugin(
          separatedAddSub = false
        ),
        new FullBarrelShifterPlugin(earlyInjection = false),
        //        new LightShifterPlugin,
        new HazardSimplePlugin(
          bypassExecute           = true,
          bypassMemory            = true,
          bypassWriteBack         = true,
          bypassWriteBackBuffer   = true,
          pessimisticUseSrc       = false,
          pessimisticWriteRegFile = false,
          pessimisticAddressMatch = false
        ),
        //        new HazardSimplePlugin(false, true, false, true),
        //        new HazardSimplePlugin(false, false, false, false),
        new MulPlugin,
        new MulDivIterativePlugin(
          genMul = false,
          genDiv = true,
          mulUnrollFactor = 32,
          divUnrollFactor = 1
        ),
        //          new DivPlugin,
        new CsrPlugin(CsrPluginConfig.all2(0x80000020l).copy(ebreakGen = false, mhartid = id, misaExtensionsInit = Riscv.misaToInt("imas"))),
        //          new CsrPlugin(//CsrPluginConfig.all2(0x80000020l).copy(ebreakGen = true)/*
        //             CsrPluginConfig(
        //            catchIllegalAccess = false,
        //            mvendorid      = null,
        //            marchid        = null,
        //            mimpid         = null,
        //            mhartid        = null,
        //            misaExtensionsInit = 0,
        //            misaAccess     = CsrAccess.READ_ONLY,
        //            mtvecAccess    = CsrAccess.WRITE_ONLY,
        //            mtvecInit      = 0x80000020l,
        //            mepcAccess     = CsrAccess.READ_WRITE,
        //            mscratchGen    = true,
        //            mcauseAccess   = CsrAccess.READ_ONLY,
        //            mbadaddrAccess = CsrAccess.READ_ONLY,
        //            mcycleAccess   = CsrAccess.NONE,
        //            minstretAccess = CsrAccess.NONE,
        //            ecallGen       = true,
        //            ebreakGen      = true,
        //            wfiGenAsWait   = false,
        //            wfiGenAsNop    = true,
        //            ucycleAccess   = CsrAccess.NONE
        //          )),
        new BranchPlugin(
          earlyBranch = false,
          catchAddressMisaligned = true,
          fenceiGenAsAJump = false
        ),
        new YamlPlugin(s"cpu$id.yaml")
      )
    )
    if(id == 0) config.plugins += new DebugPlugin(null)
    config
  }
  def vexRiscvCluster(cpuCount : Int) = VexRiscvSmpCluster(
    debugClockDomain = ClockDomain.current.copy(reset = Bool().setName("debugResetIn")),
    p = VexRiscvSmpClusterParameter(
      cpuConfigs = List.tabulate(cpuCount) {
        vexRiscvConfig(_)
      }
    )
  )
  def main(args: Array[String]): Unit = {
    SpinalVerilog {
      vexRiscvCluster(4)
    }
  }
}



object VexRiscvSmpClusterTestInfrastructure{
  val REPORT_OFFSET = 0xF8000000
  val REPORT_THREAD_ID = 0x00
  val REPORT_THREAD_COUNT = 0x04
  val REPORT_END = 0x08
  val REPORT_BARRIER_START = 0x0C
  val REPORT_BARRIER_END   = 0x10

  val PUTC = 0x00
  val GETC = 0x04
  val CLINT_ADDR = 0x10000
  val CLINT_IPI_ADDR = CLINT_ADDR+0x0000
  val CLINT_CMP_ADDR = CLINT_ADDR+0x4000
  val CLINT_TIME_ADDR = CLINT_ADDR+0xBFF8

  def ram(dut : VexRiscvSmpCluster) = {
    import spinal.core.sim._
    val cpuCount = dut.cpus.size
    val ram = new BmbMemoryAgent(0x100000000l){
      case class Report(hart : Int, code : Int, data : Int){
        override def toString: String = {
          f"CPU:$hart%2d ${code}%3x -> $data%3d"
        }
      }
      val reports = ArrayBuffer.fill(cpuCount)(ArrayBuffer[Report]())
      onSimEnd{
        for((list, hart) <- reports.zipWithIndex){
          println(f"\n\n**** CPU $hart%2d ****")
          for((report, reportId) <- list.zipWithIndex){
            println(f"  $reportId%3d : ${report.code}%3x -> ${report.data}%3d")
          }
        }
      }

      val writeTable = mutable.HashMap[Int, Int => Unit]()
      val readTable = mutable.HashMap[Int, () => Int]()
      def onWrite(address : Int)(body : Int => Unit) = writeTable(address) = body
      def onRead(address : Int)(body : => Int) = readTable(address) = () => body

      var writeData = 0
      var readData = 0
      var reportWatchdog = 0
      val cpuEnd = Array.fill(cpuCount)(false)
      val barriers = mutable.HashMap[Int, Int]()
      override def setByte(address: Long, value: Byte): Unit = {
        if((address & 0xF0000000l) != 0xF0000000l) return  super.setByte(address, value)
        val byteId = address & 3
        val mask = 0xFF << (byteId*8)
        writeData = (writeData & ~mask) | ((value.toInt << (byteId*8)) & mask)
        if(byteId != 3) return
        val offset = (address & ~0xF0000000l)-3
        //        println(s"W[0x${offset.toHexString}] = $writeData @${simTime()}")
        offset match {
          case _ if offset >= 0x8000000 && offset < 0x9000000 => {
            val report = Report(
              hart = ((offset & 0xFF0000) >> 16).toInt,
              code = (offset & 0x00FFFF).toInt,
              data = writeData
            )
            println(report)
            reports(report.hart) += report
            reportWatchdog += 1
            import report._
            code match {
              case REPORT_THREAD_ID => assert(data == hart)
              case REPORT_THREAD_COUNT => assert(data == cpuCount)
              case REPORT_END => assert(data == 0); assert(cpuEnd(hart) == false); cpuEnd(hart) = true; if(!cpuEnd.exists(_ == false)) simSuccess()
              case REPORT_BARRIER_START => {
                val counter = barriers.getOrElse(data, 0)
                assert(counter < cpuCount)
                barriers(data) = counter + 1
              }
              case REPORT_BARRIER_END => {
                val counter = barriers.getOrElse(data, 0)
                assert(counter == cpuCount)
              }
            }
          }
          case _ => writeTable.get(offset.toInt) match {
            case Some(x) => x(writeData)
            case _ => simFailure(f"\n\nWrite at ${address-3}%8x with $writeData%8x")
          }
        }
      }

      override def getByte(address: Long): Byte = {
        if((address & 0xF0000000l) != 0xF0000000l) return super.getByte(address)
        val byteId = address & 3
        val offset = (address & ~0xF0000000l)
        if(byteId == 0) readData = readTable.get(offset.toInt) match {
          case Some(x) => x()
          case _ => simFailure(f"\n\nRead at $address%8x")
        }
        (readData >> (byteId*8)).toByte
      }

      val clint = new {
        val cmp = Array.fill(cpuCount)(0l)
      }

      onWrite(PUTC)(data => print(data.toChar))
//      onWrite(GETC)(data => System.in.read().toInt)

      onRead(CLINT_TIME_ADDR)(simTime().toInt)
      onRead(CLINT_TIME_ADDR+4)((simTime() >> 32).toInt)
      for(hartId <- 0 until cpuCount){
        onWrite(CLINT_IPI_ADDR + hartId*4) {data =>
          val mask = 1l << hartId
          val value = (dut.io.softwareInterrupts.toLong & ~mask) | (if(data == 1) mask else 0)
          dut.io.softwareInterrupts #= value
        }
        onRead(CLINT_CMP_ADDR + hartId*8)(clint.cmp(hartId).toInt)
        onRead(CLINT_CMP_ADDR + hartId*8+4)((clint.cmp(hartId) >> 32).toInt)
        onWrite(CLINT_CMP_ADDR + hartId*8)(data => clint.cmp(hartId) = (clint.cmp(hartId) & 0xFFFFFFFF00000000l) | data)
        onWrite(CLINT_CMP_ADDR + hartId*8+4)(data => (clint.cmp(hartId) & 0x00000000FFFFFFFFl) | (data << 32))
      }

      var time = 0l
      periodicaly(100){
        time += 10
        var timerInterrupts = 0l
        for(i <- 0 until cpuCount){
          if(clint.cmp(i) < time) timerInterrupts |= 1l << i
        }
        dut.io.timerInterrupts #= timerInterrupts
      }

    }
    dut.io.iMems.foreach(ram.addPort(_,0,dut.clockDomain,true, withStall))
    ram.addPort(dut.io.dMem,0,dut.clockDomain,true, withStall)
    ram
  }
  def init(dut : VexRiscvSmpCluster): Unit ={
    import spinal.core.sim._
//    dut.clockDomain.forkSimSpeedPrinter(1.0)
    dut.clockDomain.forkStimulus(10)
    dut.debugClockDomain.forkStimulus(10)
    JtagTcp(dut.io.jtag, 100)
  }
}

object VexRiscvSmpClusterTest extends App{
  import spinal.core.sim._

  val simConfig = SimConfig
//  simConfig.withWave
  simConfig.allOptimisation
  simConfig.addSimulatorFlag("--threads 1")

  val cpuCount = 4
  val withStall = true

  simConfig.compile(VexRiscvSmpClusterGen.vexRiscvCluster(cpuCount)).doSimUntilVoid(seed = 42){dut =>
    SimTimeout(10000*10*cpuCount)
    VexRiscvSmpClusterTestInfrastructure.init(dut)
    val ram = VexRiscvSmpClusterTestInfrastructure.ram(dut)
    ram.memory.loadBin(0x80000000l, "src/test/cpp/raw/smp/build/smp.bin")
    periodicaly(20000*10){
      assert(ram.reportWatchdog != 0)
      ram.reportWatchdog = 0
    }
  }
}


object VexRiscvSmpClusterOpenSbi extends App{
  import spinal.core.sim._

  val simConfig = SimConfig
  simConfig.withWave
  simConfig.allOptimisation
  simConfig.addSimulatorFlag("--threads 1")

  val cpuCount = 4
  val withStall = false

  simConfig.compile(VexRiscvSmpClusterGen.vexRiscvCluster(cpuCount)).doSimUntilVoid(seed = 42){dut =>
    VexRiscvSmpClusterTestInfrastructure.init(dut)
    val ram = VexRiscvSmpClusterTestInfrastructure.ram(dut)
    ram.memory.loadBin(0x80000000l, "../opensbi/build/platform/spinal/vexriscv/sim/smp/firmware/fw_payload.bin")
//    ram.memory.loadBin(0x80000000l, "../opensbi/build/platform/spinal/vexriscv/sim/smp/firmware/fw_jump.bin")
  }
}