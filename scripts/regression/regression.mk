.ONESHELL:


regression_random:
	cd ../..
	export VEXRISCV_REGRESSION_CONFIG_COUNT=4
	export VEXRISCV_REGRESSION_FREERTOS_COUNT=1
	export VEXRISCV_REGRESSION_ZEPHYR_COUNT=4
	export VEXRISCV_REGRESSION_THREAD_COUNT=1
	sbt "testOnly vexriscv.TestIndividualFeatures"

regression_random_linux:
	cd ../..
	export VEXRISCV_REGRESSION_CONFIG_COUNT=3
	export VEXRISCV_REGRESSION_CONFIG_LINUX_RATE=1.0
	export VEXRISCV_REGRESSION_FREERTOS_COUNT=2
	export VEXRISCV_REGRESSION_ZEPHYR_COUNT=4
	export VEXRISCV_REGRESSION_THREAD_COUNT=1
	sbt "testOnly vexriscv.TestIndividualFeatures"


regression_random_machine_os:
	cd ../..
	export VEXRISCV_REGRESSION_CONFIG_COUNT=30
	export VEXRISCV_REGRESSION_CONFIG_LINUX_RATE=0.0
	export VEXRISCV_REGRESSION_CONFIG_MACHINE_OS_RATE = 1.0
	export VEXRISCV_REGRESSION_FREERTOS_COUNT=2
	export VEXRISCV_REGRESSION_ZEPHYR_COUNT=4
	export VEXRISCV_REGRESSION_THREAD_COUNT=1
	sbt "testOnly vexriscv.TestIndividualFeatures"

regression_random_baremetal:
	cd ../..
	export VEXRISCV_REGRESSION_CONFIG_COUNT=40
	export VEXRISCV_REGRESSION_CONFIG_LINUX_RATE=0.0
	export VEXRISCV_REGRESSION_CONFIG_MACHINE_OS_RATE = 0.0
	export VEXRISCV_REGRESSION_FREERTOS_COUNT=1
	export VEXRISCV_REGRESSION_ZEPHYR_COUNT=no
	export VEXRISCV_REGRESSION_THREAD_COUNT=1
	sbt "testOnly vexriscv.TestIndividualFeatures"


regression_dhrystone:
	cd ../..
	sbt "testOnly vexriscv.DhrystoneBench"
