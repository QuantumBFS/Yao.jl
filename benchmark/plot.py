#!/usr/bin/env python
import sys
sys.path.insert(0, "../")
from plotlib import *
import fire

def _show_benchres(datafile, savefile, legends):
    if isinstance(datafile, str):
        data = np.loadtxt(datafile).reshape([6, len(legends)])
    else:
        data = datafile
    with DataPlt(filename=savefile, figsize=(5,4)) as dp:
        plt.plot(np.arange(10, 28, 3), data/1e3)
        plt.legend(legends)
        plt.yscale('log')
        plt.ylabel(r'$t/ms$')
        plt.xlabel(r'$N$')
        plt.ylim(1e-2, 1e2)

def fbench(token, legends, version=7):
    if version == 6:
        ydata = np.loadtxt('yao/v0.6.3-pre.1/%s-report.dat'%token).reshape([6,-1])
    else:
        ydata = np.loadtxt('yao/v0.7.0-alpha.147/%s-report.dat'%token).reshape([6,-1])
    qdata = np.loadtxt('projectq/0.3.6/%s-report.dat'%token).reshape([6,-1])
    _show_benchres(np.concatenate([qdata, ydata], axis=1), '../docs/src/assets/figures/%s-bench.png'%token, ['Q-%s'%l for l in legends] + ['Y-%s'%l for l in legends])

class PltBench():
    def xyz(self):
        fbench("xyz", ['X', 'Y', 'Z'], 7)

    def cxyz(self):
        fbench("cxyz", ['CX', 'CY', 'CZ'], 7)

    def repeatxyz(self):
        fbench("repeatxyz", ['X(2-7)', 'Y(2-7)', 'Z(2-7)'], 7)

    def hgate(self):
        qdata = np.loadtxt('projectq/0.3.6/h-report.dat').reshape([6, 3])
        #ydata = np.loadtxt('yao/v0.6.3-pre.1/cxyz-report.dat').reshape([6, 3])
        ydata = np.loadtxt('yao/v0.7.0-alpha.147/h-report.dat').reshape([6, 3])

        qdata[:,2]/=6
        ydata[:,2]/=6
        _show_benchres(np.concatenate([qdata, ydata], axis=1), '../docs/src/assets/figures/hgate-bench.png', ['Q-H', 'Q-CH', 'Q-H(2-7) (time / 6)', 'Y-H', 'Y-CH', 'Y-H(2-7) (time / 6)'])

    def toffoli(self):
        fbench("toffoli", ['Toffoli'], 7)

    def rot(self):
        fbench("rot", ['Rx', 'Ry', 'Rz'], 7)

if __name__ == '__main__':
    fire.Fire(PltBench)
