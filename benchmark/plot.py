#!/usr/bin/env python
import sys
sys.path.insert(0, "../")
from plotlib import *
import fire

def _show_benchres(data, savefile, legends):
    M = data.shape[1]//2
    colors = [[0.3+0.7*np.random.random(), 0.5*np.random.random(), 0, 1] for i in range(M)] + [[0, 0.5+0.5*np.random.random(), 0.3+0.7*np.random.random(), 1] for i in range(M)]
    with DataPlt(filename=savefile, figsize=(5,4)) as dp:
        #plt.plot(np.arange(10, 28, 3), data/1e3, color=np.array(colors))
        for i in range(2*M):
            plt.plot(np.arange(10, 28, 3), data[:,i]/1e3, color=np.array(colors[i]))
        plt.legend(legends)
        plt.yscale('log')
        plt.ylabel(r'$t/ms$')
        plt.xlabel(r'$N$')
        plt.ylim(1e-2, 1e2)

def fbench(token, legends, version=7, ftype='png'):
    if version == 6:
        ydata = np.loadtxt('yao/v0.6.3-pre.1/%s-report.dat'%token).reshape([6,-1])
    else:
        ydata = np.loadtxt('yao/v0.7.0-alpha.147/%s-report.dat'%token).reshape([6,-1])
    qdata = np.loadtxt('projectq/0.3.6/%s-report.dat'%token).reshape([6,-1])
    _show_benchres(np.concatenate([qdata, ydata], axis=1), '../docs/src/assets/benchmarks/%s-bench.%s'%(token, ftype), ['Q-%s'%l for l in legends] + ['Y-%s'%l for l in legends])

class PltBench():
    def __init__(self):
        self.ftype='png'

    def xyz(self):
        fbench("xyz", ['X', 'Y', 'Z'], 7, self.ftype)

    def cxyz(self):
        fbench("cxyz", ['CX', 'CY', 'CZ'], 7, self.ftype)

    def repeatxyz(self):
        fbench("repeatxyz", ['X(2-7)', 'Y(2-7)', 'Z(2-7)'], 7, self.ftype)

    def hgate(self):
        qdata = np.loadtxt('projectq/0.3.6/h-report.dat').reshape([6, 3])
        #ydata = np.loadtxt('yao/v0.6.3-pre.1/cxyz-report.dat').reshape([6, 3])
        ydata = np.loadtxt('yao/v0.7.0-alpha.147/h-report.dat').reshape([6, 3])

        qdata[:,2]/=6
        ydata[:,2]/=6
        _show_benchres(np.concatenate([qdata, ydata], axis=1), '../docs/src/assets/benchmarks/hgate-bench.%s'%self.ftype, ['Q-H', 'Q-CH', 'Q-H(2-7) (time / 6)', 'Y-H', 'Y-CH', 'Y-H(2-7) (time / 6)'])

    def toffoli(self):
        fbench("toffoli", ['Toffoli'], 7, self.ftype)

    def rot(self):
        fbench("rot", ['Rx', 'Ry', 'Rz'], 7, self.ftype)

    def crot(self):
        fbench("crot", ['CRx', 'CRy', 'CRz'], 7, self.ftype)

    def showall(self, ftype='png'):
        self.ftype = ftype
        self.xyz()
        self.repeatxyz()
        self.hgate()
        self.toffoli()
        self.rot()
        self.crot()

if __name__ == '__main__':
    fire.Fire(PltBench)
