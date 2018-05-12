def KL_divergence(p, q):
    return cross_entropy(p, q) - entropy(p)


def cross_entropy(p, q):
    q = np.maximum(q, 1e-15)
    return -(p * np.log(q)).sum()


def entropy(p):
    p = np.maximum(p, 1e-15)
    return -(p * np.log(p)).sum()


def sample_from_prob(x, pl, num_sample):
    '''
    sample x from probability.
    '''
    pl = 1. / pl.sum() * pl
    indices = np.arange(len(x))
    res = np.random.choice(indices, num_sample, p=pl)
    return np.array([x[r] for r in res])


def prob_from_sample(dataset, hndim, packbits):
    '''
    emperical probability from data.
    '''
    if packbits:
        dataset = packnbits(dataset).ravel()
    p_data = np.bincount(dataset, minlength=hndim)
    p_data = p_data / float(np.sum(p_data))
    return p_data

i
