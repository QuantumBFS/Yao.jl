'''
Context for applying gates.
'''

import numpy as np
import os, pdb

try:
    from projectq.cengines import MainEngine
    from projectq.backends import CircuitDrawer, Simulator, IBMBackend
    from projectq.ops import Measure
except:
    print('warning: fail to import projectq')

TEX_FOLDER = 'data'
TEX_FILENAME = '_temp.tex'

class ProjectQContext(object):
    '''
    Context for running circuits.

    Args:
        num_bit (int): number of bits in register.
        task ('ibm'|'draw'|'simulate'): task that decide the environment type.
        ibm_config (dict): extra arguments for IBM backend.
    '''

    def __init__(self, num_bit, task, ibm_config=None):
        self.task = task
        self.num_bit = num_bit
        self.ibm_config = ibm_config

    def __enter__(self):
        '''
        Enter context,

        Attributes:
            eng (MainEngine): main engine.
            backend ('graphical' or 'simulate'): backend used.
            qureg (Qureg): quantum register.
        '''
        if self.task=='ibm':
            import projectq.setups.ibm
        else:
            import projectq.setups.default

        # create a main compiler engine with a specific backend:
        if self.task == 'draw':
            self.backend = CircuitDrawer()
            # locations = {0: 0, 1: 1, 2: 2, 3:3} # swap order of lines 0-1-2.
            # self.backend.set_qubit_locations(locations)
        elif self.task == 'simulate':
            self.backend = Simulator()
        elif self.task == 'ibm':
            # choose device
            device = self.ibm_config.get('device', 'ibmqx2' if self.num_bit<=5 else 'ibmqx5')
            # check data
            if self.ibm_config is None:
                raise
            if device == 'ibmqx5':
                device_num_bit = 16
            else:
                device_num_bit = 5
            if device_num_bit < self.num_bit:
                raise AttributeError('device %s has not enough qubits for %d bit simulation!'%(device, self.num_bit))

            self.backend = IBMBackend(use_hardware=True, num_runs=self.ibm_config['num_runs'],
                    user=self.ibm_config['user'],
                    password=self.ibm_config['password'],
                    device=device, verbose=True)
        else:
            raise ValueError('engine %s not defined' % self.task)
        self.eng = MainEngine(self.backend)
        # initialize register
        self.qureg = self.eng.allocate_qureg(self.num_bit)
        return self

    def __exit__(self, exc_type, exc_val, traceback):
        '''
        exit, meanwhile cheat and get wave function.

        Attributes:
            wf (1darray): for 'simulate' task, the wave function vector.
            res (1darray): for 'ibm' task, the measurements output.
        '''
        if traceback is not None:
            return False
        if self.task == 'draw':
            self._viz_circuit()
        elif self.task == 'simulate':
            self.wf = self.get_wf()
            Measure | self.qureg
            self.eng.flush()
        elif self.task == 'ibm':
            Measure | self.qureg
            self.eng.flush()
            self.res = self.backend.get_probabilities(self.qureg)
        else:
            raise
        return self

    def get_wf(self):
        self.eng.flush()
        order, qvec = self.backend.cheat()
        wf = np.array(qvec)
        order = [order[i] for i in range(len(self.qureg))]
        wf = np.transpose(wf.reshape([2]*len(self.qureg), order='F'), axes=order).ravel(order='F')
        return wf

    def _viz_circuit(self):
        Measure | self.qureg
        self.eng.flush()
        # print latex code to draw the circuit:
        s = self.backend.get_latex()

        # save graph to latex file
        os.chdir(TEX_FOLDER)
        with open(TEX_FILENAME, 'w') as f:
            f.write(s)

        # texfile = os.path.join(folder, 'circuit-%d.tex'%bench_id)
        pdffile = TEX_FILENAME[:-3]+'pdf'
        os.system('pdflatex %s'%TEX_FILENAME)


class ScipyContext(object):
    '''
    Scipy context for running circuits.

    Args:
        num_bit (int): number of bits in register.
        ibm_config (dict): extra arguments for IBM backend.
    '''

    def __init__(self, num_bit, *args, **kwargs):
        self.num_bit = num_bit

    def __enter__(self):
        '''
        Enter context,

        Attributes:
            eng (MainEngine): main engine.
            backend ('graphical' or 'simulate'): backend used.
            qureg (Qureg): quantum register.
        '''
        self.qureg = np.zeros(2**self.num_bit, dtype='complex128')
        self.qureg[0] = 1
        return self

    def __exit__(self, exc_type, exc_val, traceback):
        '''
        exit, meanwhile cheat and get wave function.

        Attributes:
            wf (1darray): for 'simulate' task, the wave function vector.
            res (1darray): for 'ibm' task, the measurements output.
        '''
        if traceback is not None:
            return False
        self.wf = self.qureg
        return self
