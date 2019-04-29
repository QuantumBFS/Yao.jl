#!/usr/bin/env python
import numpy as np
import matplotlib.pyplot as plt
import fire
import viznet
from viznet import NodeBrush, EdgeBrush

def _show():
    plt.axis('off')
    plt.axis('equal')
    plt.show()

class Ploter():
    def framework(self):
        with viznet.DynamicShow(figsize=(6,4), filename="framework.png") as dp:
            grid = viznet.Grid((3.0, 1.5), offset=(2,2))
            edge = EdgeBrush('->', lw=2., color='r')

            # define an mpo
            mpo = NodeBrush('box', color='cyan', roundness=0.2, size=(1.0, 0.4))

            # generate two mpos
            Const = mpo >> grid[0:2, 0:1]; Const.text('LuxurySparse')
            Intrinsics = mpo >> grid[3:5, 0:1]; Intrinsics.text('Binary Op')
            Intrinsics = mpo >> grid[6:8, 0:1]; Intrinsics.text('Cache Server')
            Register = mpo >> grid[3:5, 2:3]; Register.text('Register')
            Block = mpo >> grid[0:8, 4:5]; Block.text('Blocks (Operator Tree)')
            Extensions = mpo >> grid[4.5:8, 6:7]; Extensions.text('Boost & Extensions')
            Interface = mpo >> grid[0:3.5, 6:7]; Interface.text('Interface')
            Applications = mpo >> grid[0:8, 8:9]; Applications.text('Applications')

if __name__ == '__main__':
    fire.Fire(Ploter)
