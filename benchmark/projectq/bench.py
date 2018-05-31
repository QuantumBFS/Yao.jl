#!/usr/bin/env python
import numpy as np
import time, fire
from contexts import ProjectQContext
from projectq import ops


def qbenchmark(func, num_bit, num_bench=1000):
    with ProjectQContext(num_bit, 'simulate') as cc:
        qureg = cc.qureg
        eng = qureg.engine
        t0 = time.time()
        for i in range(num_bench):
            func(qureg)
            eng.flush()
        t1 = time.time()
    return (t1-t0)/num_bench

def bG(G):
    return lambda qureg: G|qureg[2]
def bCG(G):
    return lambda qureg: ops.C(G)|(qureg[2], qureg[5])
def bRG(G):
    return lambda qureg: ops.Tensor(G)|qureg[2:8]
    #return lambda qureg: G|qureg[2:8]

NL = range(10, 28, 3)

class BenchMark():
    def xyz(self):
        tl = []
        for nsite, num_bench in zip(NL, [1000, 1000, 1000, 100, 10, 5]):
            print('========== N: %d ============'%nsite)
            for func in [bG(ops.X), bG(ops.Y), bG(ops.Z), bCG(ops.X), bCG(ops.Y), bCG(ops.Z)]:
                tl.append(qbenchmark(func, nsite, num_bench)*1e6)
        np.savetxt('xyz-report.dat', tl)

    def repeatxyz(self):
        tl = []
        for nsite, num_bench in zip(NL, [1000, 1000, 1000, 100, 10, 5]):
            print('========== N: %d ============'%nsite)
            for func in [bRG(ops.X), bRG(ops.Y), bRG(ops.Z)]:
                tl.append(qbenchmark(func, nsite, num_bench)*1e6)
        np.savetxt('repeatxyz-report.dat', tl)


if __name__ == '__main__':
    fire.Fire(BenchMark)
