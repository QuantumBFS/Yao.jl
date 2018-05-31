#!/usr/bin/env python
from plotlib import *
import fire

class PltBench():
    def xyz(self):
        data = np.loadtxt('xyz-report.dat').reshape([6, 6])
        with DataPlt(filename='projectq-xyz.png', figsize=(5,4)) as dp:
            plt.plot(np.arange(10, 28, 3), data/1e3)
            plt.legend(['X', 'Y', 'Z', 'CX', 'CY', 'CZ'])
            plt.yscale('log')
            plt.ylabel(r'$t/ms$')
            plt.xlabel(r'$N$')

    def repeatxyz(self):
        data = np.loadtxt('repeatxyz-report.dat').reshape([6, 3])
        with DataPlt(filename='projectq-repeatxyz.png', figsize=(5,4)) as dp:
            plt.plot(np.arange(10, 28, 3), data/1e3)
            plt.legend(['X(2-7)', 'Y(2-7)', 'Z(2-7)'])
            plt.yscale('log')
            plt.ylabel(r'$t/ms$')
            plt.xlabel(r'$N$')


    def comparer(self):
        data = np.loadtxt('xyz-report.dat').reshape([6, 6])
        datar = np.loadtxt('repeatxyz-report.dat').reshape([6, 3])
        with DataPlt(filename='projectq-comparerepeat.png', figsize=(5,4)) as dp:
            plt.plot(np.arange(10, 28, 3), data[:,0]/1e3)
            plt.plot(np.arange(10, 28, 3), datar[:,0]/1e3/6)
            plt.legend(['X(2)', 'X(2-7) (time devided by 6)'])
            plt.yscale('log')
            plt.ylabel(r'$t/ms$')
            plt.xlabel(r'$N$')


if __name__ == '__main__':
    fire.Fire(PltBench)
