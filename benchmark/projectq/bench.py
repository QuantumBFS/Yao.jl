import numpy as np
import time
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

def run():
    tl = []
    for nsite, num_bench in ([10, 1000], [13, 1000], [16, 1000], [19, 100], [22, 10], [25, 1]):
        print('========== N: %d ============'%nsite)
        for func in [bG(ops.X), bG(ops.Y), bG(ops.Z), bCG(ops.X), bCG(ops.Y), bCG(ops.Z)]:
            tl.append(qbenchmark(func, nsite)*1e6)
    np.savetxt('ProjectQ_report.dat', tl)
    #print(np.array(tl[1:])/tl[:-1])

if __name__ == '__main__':
    run()
