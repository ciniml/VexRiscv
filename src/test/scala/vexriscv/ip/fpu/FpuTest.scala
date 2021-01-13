package vexriscv.ip.fpu

import java.lang

import org.scalatest.FunSuite
import spinal.core.SpinalEnumElement
import spinal.core.sim._
import spinal.lib.experimental.math.Floating
import spinal.lib.sim._

import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer
import scala.util.Random

class FpuTest extends FunSuite{


  test("directed"){
    val p = FpuParameter(
      internalMantissaSize = 23,
      withDouble = false,
      sourceWidth = 0
    )

    SimConfig.withFstWave.compile(new FpuCore(p)).doSim(seed = 42){ dut =>
      dut.clockDomain.forkStimulus(10)




      val cpus = for(id <- 0 until 1 << p.sourceWidth) yield new {
        val cmdQueue = mutable.Queue[FpuCmd => Unit]()
        val commitQueue = mutable.Queue[FpuCommit => Unit]()
        val rspQueue = mutable.Queue[FpuRsp => Unit]()

        def loadRaw(rd : Int, value : BigInt): Unit ={
          cmdQueue += {cmd =>
            cmd.source #= id
            cmd.opcode #= cmd.opcode.spinalEnum.LOAD
            cmd.value.randomize()
            cmd.rs1.randomize()
            cmd.rs2.randomize()
            cmd.rs3.randomize()
            cmd.rd #= rd
          }
          commitQueue += {cmd =>
            cmd.source #= id
            cmd.write #= true
            cmd.value #= value
          }
        }

        def load(rd : Int, value : Float): Unit ={
          loadRaw(rd, lang.Float.floatToIntBits(value).toLong & 0xFFFFFFFFl)
        }

        def storeRaw(rs : Int)(body : FpuRsp => Unit): Unit ={
          cmdQueue += {cmd =>
            cmd.source #= id
            cmd.opcode #= cmd.opcode.spinalEnum.STORE
            cmd.value.randomize()
            cmd.rs1.randomize()
            cmd.rs2 #= rs
            cmd.rs3.randomize()
            cmd.rd.randomize()
          }

          rspQueue += body
        }

        def storeFloat(rs : Int)(body : Float => Unit): Unit ={
          storeRaw(rs){rsp => body(lang.Float.intBitsToFloat(rsp.value.toLong.toInt))}
        }

        def mul(rd : Int, rs1 : Int, rs2 : Int): Unit ={
          cmdQueue += {cmd =>
            cmd.source #= id
            cmd.opcode #= cmd.opcode.spinalEnum.MUL
            cmd.value.randomize()
            cmd.rs1 #= rs1
            cmd.rs2 #= rs2
            cmd.rs3.randomize()
            cmd.rd #= rd
          }
        }

        def add(rd : Int, rs1 : Int, rs2 : Int): Unit ={
          cmdQueue += {cmd =>
            cmd.source #= id
            cmd.opcode #= cmd.opcode.spinalEnum.ADD
            cmd.value.randomize()
            cmd.rs1 #= rs1
            cmd.rs2 #= rs2
            cmd.rs3.randomize()
            cmd.rd #= rd
          }
        }

        def fma(rd : Int, rs1 : Int, rs2 : Int, rs3 : Int): Unit ={
          cmdQueue += {cmd =>
            cmd.source #= id
            cmd.opcode #= cmd.opcode.spinalEnum.FMA
            cmd.value.randomize()
            cmd.rs1 #= rs1
            cmd.rs2 #= rs2
            cmd.rs3 #= rs3
            cmd.rd #= rd
          }
        }
      }

      StreamDriver(dut.io.port.cmd ,dut.clockDomain){payload =>
        cpus.map(_.cmdQueue).filter(_.nonEmpty).toSeq match {
          case Nil => false
          case l => {
            l.randomPick().dequeue().apply(payload)
            true
          }
        }
      }

      StreamDriver(dut.io.port.commit ,dut.clockDomain){payload =>
        cpus.map(_.commitQueue).filter(_.nonEmpty).toSeq match {
          case Nil => false
          case l => {
            l.randomPick().dequeue().apply(payload)
            true
          }
        }
      }


      StreamMonitor(dut.io.port.rsp, dut.clockDomain){payload =>
        cpus(payload.source.toInt).rspQueue.dequeue().apply(payload)
      }

      StreamReadyRandomizer(dut.io.port.rsp, dut.clockDomain)





      val stim = for(cpu <- cpus) yield fork {
        import cpu._

        class RegAllocator(){
          var value = 0

          def allocate(): Int ={
            while(true){
              val rand = Random.nextInt(32)
              val mask = 1 << rand
              if((value & mask) == 0) {
                value |= mask
                return rand
              }
            }
            0
          }
        }
        def checkFloat(ref : Float, dut : Float): Boolean ={
          ref.abs * 1.0001 > dut.abs && ref.abs * 0.9999 < dut.abs && ref.signum == dut.signum
        }

        def randomFloat(): Float ={
          Random.nextFloat() * 1e2f * (if(Random.nextBoolean()) -1f else 1f)
        }

        def testAdd(a : Float, b : Float): Unit ={
          val rs = new RegAllocator()
          val rs1, rs2, rs3 = rs.allocate()
          val rd = Random.nextInt(32)
          load(rs1, a)
          load(rs2, b)

          add(rd,rs1,rs2)
          storeFloat(rd){v =>
            val ref = a+b
            println(f"$a + $b = $v, $ref")
            assert(checkFloat(ref, v))
          }
        }

        def testMul(a : Float, b : Float): Unit ={
          val rs = new RegAllocator()
          val rs1, rs2, rs3 = rs.allocate()
          val rd = Random.nextInt(32)
          load(rs1, a)
          load(rs2, b)

          mul(rd,rs1,rs2)
          storeFloat(rd){v =>
            val ref = a*b
            println(f"$a * $b = $v, $ref")
            assert(checkFloat(ref, v))
          }
        }


        def testFma(a : Float, b : Float, c : Float): Unit ={
          val rs = new RegAllocator()
          val rs1, rs2, rs3 = rs.allocate()
          val rd = Random.nextInt(32)
          load(rs1, a)
          load(rs2, b)
          load(rs3, c)

          fma(rd,rs1,rs2,rs3)
          storeFloat(rd){v =>
            val ref = a * b + c
            println(f"$a * $b + $c = $v, $ref")
            assert(checkFloat(ref, v))
          }
        }

//        testAdd(0.1f, 1.6f)
//        testMul(0.1f, 1.6f)
        testFma(1.1f, 2.2f, 3.0f)

        for(i <- 0 until 1000){
          testAdd(randomFloat(), randomFloat())
        }
        for(i <- 0 until 1000){
          testMul(randomFloat(), randomFloat())
        }
        for(i <- 0 until 1000){
          testFma(randomFloat(), randomFloat(), randomFloat())
        }
        for(i <- 0 until 1000){
          val tests = ArrayBuffer[() => Unit]()
          tests += (() =>{testAdd(randomFloat(), randomFloat())})
          tests += (() =>{testMul(randomFloat(), randomFloat())})
          tests += (() =>{testFma(randomFloat(), randomFloat(), randomFloat())})
          tests.randomPick().apply()
        }

        waitUntil(cpu.rspQueue.isEmpty)
      }


      stim.foreach(_.join())
      dut.clockDomain.waitSampling(100)
    }
  }
}
