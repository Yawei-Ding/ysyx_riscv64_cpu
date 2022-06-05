# 一生一芯计划 - riscv64处理器设计
## 开发进度：

1.branch - SingleCycleCPU: RISCV64IM单周期处理器核，已完成设计:
![img](README.assets/SingleCycleCPU.png)

2.branch - FiveStagePipelineCPU: 五级流水线处理器核，正在设计中。
![img](README.assets/FiveStagePipelineCPU.png)

## 运行方法：
切换目录至ysyx-workbench/am-kernels/tests/cpu-tests，执行命令：
```
make ARCH=riscv64-npc run
```
