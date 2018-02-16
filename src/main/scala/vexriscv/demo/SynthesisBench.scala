package vexriscv.demo

import spinal.core._
import spinal.lib.eda.bench._

import scala.collection.mutable.ArrayBuffer

/**
 * Created by PIC32F_USER on 16/07/2017.
 */
object VexRiscvSynthesisBench {
  def main(args: Array[String]) {

    def wrap(that : => Component) : Component = that
//    Wrap with input/output registers
//        def wrap(that : => Component) : Component = {
//          //new WrapWithReg.Wrapper(that)
//          val c = that
//          c.rework {
//            for (e <- c.getOrdredNodeIo) {
//              if (e.isInput) {
//                e.asDirectionLess()
//                e := RegNext(RegNext(in(cloneOf(e))))
//
//              } else {
//                e.asDirectionLess()
//                out(cloneOf(e)) := RegNext(RegNext(e))
//              }
//            }
//          }
//          c
//        }

    val smallestNoCsr = new Rtl {
      override def getName(): String = "VexRiscv smallest no CSR"
      override def getRtlPath(): String = "VexRiscvSmallestNoCsr.v"
      SpinalVerilog(wrap(GenSmallestNoCsr.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val smallest = new Rtl {
      override def getName(): String = "VexRiscv smallest"
      override def getRtlPath(): String = "VexRiscvSmallest.v"
      SpinalVerilog(wrap(GenSmallest.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val smallAndProductive = new Rtl {
      override def getName(): String = "VexRiscv small and productive"
      override def getRtlPath(): String = "VexRiscvSmallAndProductive.v"
      SpinalVerilog(wrap(GenSmallAndProductive.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val fullNoMmuNoCache = new Rtl {
      override def getName(): String = "VexRiscv full no MMU no cache"
      override def getRtlPath(): String = "VexRiscvFullNoMmuNoCache.v"
      SpinalVerilog(wrap(GenFullNoMmuNoCache.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }
    val fullNoMmu = new Rtl {
      override def getName(): String = "VexRiscv full no MMU"
      override def getRtlPath(): String = "VexRiscvFullNoMmu.v"
      SpinalVerilog(wrap(GenFullNoMmu.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val noCacheNoMmuMaxPerf= new Rtl {
      override def getName(): String = "VexRiscv no cache no MMU max perf"
      override def getRtlPath(): String = "VexRiscvNoCacheNoMmuMaxPerf.v"
      SpinalVerilog(wrap(GenNoCacheNoMmuMaxPerf.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val fullNoMmuMaxPerf= new Rtl {
      override def getName(): String = "VexRiscv full no MMU max perf"
      override def getRtlPath(): String = "VexRiscvFullNoMmuMaxPerf.v"
      SpinalVerilog(wrap(GenFullNoMmuMaxPerf.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val full = new Rtl {
      override def getName(): String = "VexRiscv full"
      override def getRtlPath(): String = "VexRiscvFull.v"
      SpinalVerilog(wrap(GenFull.cpu()).setDefinitionName(getRtlPath().split("\\.").head))
    }

    val rtls = List(smallestNoCsr, smallest, smallAndProductive, fullNoMmuNoCache, noCacheNoMmuMaxPerf, fullNoMmuMaxPerf, fullNoMmu, full)
   // val rtls = List(noCacheNoMmuMaxPerf, fullNoMmuMaxPerf)

    val targets = XilinxStdTargets(
      vivadoArtix7Path = "/eda/Xilinx/Vivado/2017.2/bin"
    ) ++ AlteraStdTargets(
      quartusCycloneIVPath = "/eda/intelFPGA_lite/17.0/quartus/bin",
      quartusCycloneVPath  = "/eda/intelFPGA_lite/17.0/quartus/bin"
    )

    Bench(rtls, targets, "/eda/tmp/")
  }
}


object BrieySynthesisBench {
  def main(args: Array[String]) {
    val briey = new Rtl {
      override def getName(): String = "Briey"
      override def getRtlPath(): String = "Briey.v"
      SpinalVerilog({
        val briey = new Briey(BrieyConfig.default).setDefinitionName(getRtlPath().split("\\.").head)
        briey.io.axiClk.setName("clk")
        briey
      })
    }


    val rtls = List(briey)

    val targets = XilinxStdTargets(
      vivadoArtix7Path = "/eda/Xilinx/Vivado/2017.2/bin"
    ) ++ AlteraStdTargets(
      quartusCycloneIVPath = "/eda/intelFPGA_lite/17.0/quartus/bin/",
      quartusCycloneVPath  = "/eda/intelFPGA_lite/17.0/quartus/bin/"
    )

    Bench(rtls, targets, "/eda/tmp/")
  }
}




object MuraxSynthesisBench {
  def main(args: Array[String]) {
    val murax = new Rtl {
      override def getName(): String = "Murax"
      override def getRtlPath(): String = "Murax.v"
      SpinalVerilog({
        val murax = new Murax(MuraxConfig.default).setDefinitionName(getRtlPath().split("\\.").head)
        murax.io.mainClk.setName("clk")
        murax
      })
    }


    val muraxFast = new Rtl {
      override def getName(): String = "MuraxFast"
      override def getRtlPath(): String = "MuraxFast.v"
      SpinalVerilog({
        val murax = new Murax(MuraxConfig.fast).setDefinitionName(getRtlPath().split("\\.").head)
        murax.io.mainClk.setName("clk")
        murax
      })
    }

    val rtls = List(murax, muraxFast)

    val targets = XilinxStdTargets(
      vivadoArtix7Path = "/eda/Xilinx/Vivado/2017.2/bin"
    ) ++ AlteraStdTargets(
      quartusCycloneIVPath = "/eda/intelFPGA_lite/17.0/quartus/bin/",
      quartusCycloneVPath  = "/eda/intelFPGA_lite/17.0/quartus/bin/"
    )

    Bench(rtls, targets, "/eda/tmp/")
  }
}

object AllSynthesisBench {
  def main(args: Array[String]): Unit = {
    VexRiscvSynthesisBench.main(args)
    BrieySynthesisBench.main(args)
    MuraxSynthesisBench.main(args)

  }
}