---
description: how to build and test the RISC-V CPU (single-cycle or pipeline)
---

# CPU 测试工作流

所有命令都在 `~/my_cpu/riscv32-cpu/simulator` 目录下执行。

## 选择 CPU

通过 `CPU=` 参数选择，不需要编辑 Makefile，不需要 make clean：

| CPU= 值    | 说明                           |
|------------|-------------------------------|
| `pipeline` | **默认**，五级流水线 (rv32-pipeline-cpu-new) |
| `single`   | 单周期 (rv32-single-cycle-cpu-escaper) |
| `akun`     | akun 的单周期                   |
| `old-pipe` | 旧流水线 (调试用)                |

## 常用命令

```bash
cd ~/my_cpu/riscv32-cpu/simulator

# 查看当前配置
make info
make info CPU=single

# 编译（自动按需编译，不同 CPU 有独立 build 目录）
make
make CPU=single

# 快速单测
make test T=add
make test T=add CPU=single

# 全量 softtest（35 个 cpu-tests）
make softtest
make softtest CPU=single
make softtest CPU=pipeline

# AM 指令测试
make amtest
make amtest CPU=single
make amtest CPU=pipeline

# ARCH 合规测试
make archtest
make archtest CPU=single
make archtest CPU=pipeline

# CoreMark 性能测试
make coremark
make coremark CPU=single
make coremark CPU=pipeline


# 手动指定 IMAGE 运行
make run IMAGE=../software-test/cpu-tests/build/add-riscv32-npc.bin

# 查看波形
make sim

# 清理
make clean            # 只清理当前 CPU 的 build
make clean CPU=single # 只清理 single 的 build
make cleanall         # 清理所有 CPU 的 build
```

## 完整测试流程（验收用）

```bash
cd ~/my_cpu/riscv32-cpu/simulator

# 1. softtest
make softtest

# 2. AM 指令测试
make amtest

# 3. ARCH 合规测试
make archtest

# 4. CoreMark
make coremark
```

## 注意事项

- 不同 CPU 的编译产物在 `build/pipeline/`、`build/single/` 等独立目录，**切换 CPU 不需要 make clean**
- `make menuconfig` 仍然可用
- 如果遇到奇怪的编译错误，先 `make cleanall` 再重试
