<h1 align="center">
  <br>
  BMW-Tree
  <br>
</h1>
<p align="center">
  <a href="#-key-features">Key Features</a> •
  <a href="#-authors">Authors</a> •
  <a href="#-publication">Publication</a> •
  <a href="#-get-started">Get Started</a> •
  <a href="#-license">License</a>
</p>

## 🎯 Key Features
BMW-Tree is  a new data structure for accurate, large-scale and high-throughput PIFO implementation.It is modularized, insertion-balanced and pipelinefriendly with autonomous nodes. Based on the tree, we build two
pipelined hardware designs named R-BMW and RPU-BMW. RBMW achieves high throughput while maintaining a relatively small scale, whereas RPU-BMW features both large scale and high throughput. BMW-Tree is likely to be an attractive option for the
programmable scheduler in the next-generation traffic managers.

## 👥 Authors
- [Ruyi Yao](https://ruyiyao.github.io/)(Fudan University) <ryyao20@fudan.edu.cn>  
- Zhiyu Zhang (Fudan University) <22110240078@m.fudan.edu.cn>  
- Gaojian Fang (Fudan University) <fanggj21@m.fudan.edu.cn>  
- Peixuan Gao (New York University) <pg1540@nyu.edu>  
- Sen Liu (Fudan University) <senliu@fudan.edu.cn>  
- Yibo Fan (State Key Laboratory of ASIC and System, Fudan University) <fanyibo@fudan.edu.cn>  
- [Yang Xu](https://yangxu.info/) (Fudan University, Peng Cheng Laboratory) <xuy@fudan.edu.cn>  
- H. Jonathan Chao (New York University) <chao@nyu.edu>  

## 📜 Publication
This work is published in ACM SIGCOMM 2023:  
**BMW Tree: Large-scale, High-throughput and Modular PIFO Implementation using Balanced Multi-Way Sorting Tree**  
[📄 Paper Link](https://dl.acm.org/doi/10.1145/3603269.3604862)  

## 🚄 Get Started

### 🕶️ Overview

Push-In-First-Out (PIFO) queue has been extensively studied as a programmable scheduler. To achieve accurate, large-scale, and high-throughput PIFO implementation, we propose the Balanced Multi-way (BMW) Sorting Tree for real-time packet sorting. The tree is highly modularized, insertion-balanced and pipeline-friendly
with autonomous nodes. Based on it, we design two simple and efficient hardware designs. The first one is a register-based (R-BMW) scheme. With a pipeline, it features an impressively high and stable throughput without any frequency reduction theoretically even under more levels. We
then propose Ranking Processing Units to drive the BMW-Tree (RPU-BMW) to improve the scalability, where nodes are stored in SRAMs and dynamically loaded into/off from RPUs. As the capacity of BMW-Tree grows exponentially, only a few RPUs are needed for
a large scale. The evaluation shows that when deployed on the Xilinx Alveo U200 card, R-BMW improves the throughput by 4.8x compared to the original PIFO implementation, while exhibiting a similar capacity. RPU-BMW is synthesized in GlobalFoundries 28nm process,
costing a modest 0.522% (1.043mm2 ) chip area and 0.57MB off-chip memory to support 87k flows at 200Mpps. To our best knowledge, RPU-BMW is the first accurate PIFO implementation supporting over 80k flows at as fast as 200Mpps.

### ⚙️ Requirements
**Hardware Requirements**

* Our testbed evaluation is conducted on the Xilinx Alveo U200 Data Center Accelerator Card.

**Software Requirements**

* ns-3: ns-3.26
* [Vivado Design Suite](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html) >= 2018.3 (We used the 2018.3 version in our experiments. Newer versions should be compatible with 2018.3, but we have not tested with older versions.)

## 📖 License

The project is released under the Apache-2.0 License.
