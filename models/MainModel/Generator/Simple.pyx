from __future__ import division

import matplotlib.animation as animation
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

from random import randint, choice, seed
from scipy import stats
import numpy as np

import sys
import os
import psutil

mydir = os.path.expanduser("~/")
sys.path.append(mydir + "tools/metrics")
import metrics
sys.path.append(mydir + "/GitHub/hydrobide/tools/LBM")
import LBM
sys.path.append(mydir + "/GitHub/hydrobide/tools/bide")
import bide


def get_rand_params():
    """ Get random model parameter values. Others are chosen in bide.pyx """

    motion = choice(['fluid', 'conveyor', 'random_walk', 'uncorrelated'])
    D = str()
    if motion == 'uncorrelated' or motion == 'random_walk':
        D = choice([2, 3])
    else:
        D = 2

    width = choice([5, 10])
    height = choice([5, 10])

    length = choice([5, 10])
    alpha = np.random.uniform(0.95, 0.99)

    reproduction = choice(['clonal', 'sexual'])
    mutation = choice(['yes', 'no'])
    predators = choice(['yes', 'no'])
    parasites = choice(['yes', 'no'])
    symbionts = choice(['yes', 'no'])
    env_gradient = choice(['no', 'yes'])

    # richness of the metacommunity
    J = choice([100, 1000, 10000])

    # size of starting community
    seedcom = choice([0, 10, 100, 1000])

    # individuals immigrating per time step
    m = choice([0, 2, 4, 8])

    # resource particles flowing in per time step
    r = choice([0, 10, 50, 100])

    # maximum number of resources types
    nr = choice([1, 2, 4, 8, 16, 32])

    # maximum resource particle size
    rmax = choice([500, 1000, 2000, 4000, 8000])

    # mean and standard deviation for number of prey
    avg_prey = [np.random.uniform(0, 10), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for number of symbionts
    avg_symb = [np.random.uniform(0, 10), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for number of parasites
    avg_parasite = [np.random.uniform(0, 10), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for specific growth rate
    avg_growth = [np.random.uniform(0.1, 1.0), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for propagule cell quota
    avg_Q = [np.random.uniform(0.1, 1.0), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for specific maintenance
    avg_maint = [np.random.uniform(0.01, 0.1), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for specific active dispersal
    avg_disp = [np.random.uniform(0.01, 1.0), np.random.uniform(0.01, 0.1)]

    # mean and standard deviation for specific resource use efficiency
    avg_res = [np.random.uniform(0.01, 1.0), np.random.uniform(0.01, 0.1)]

    return [width, height, length, alpha, motion, D, reproduction, mutation, predators, parasites, symbionts, env_gradient, J, seedcom, m, r, nr, rmax, avg_prey, avg_symb, avg_parasite, avg_growth, avg_Q, avg_maint, avg_disp, avg_res]


######### Function called for each successive animation frame ##################

def nextFrame(arg):	# arg is the frame number

    global width, height, length, Rates, u0, shift, sign, barrier, rho, ux, uy, n0, nN, nS, nE, nW, nNE, nNW, nSE, nSW
    global IndXcoords, IndYcoords, IndZcoords, Ind_scatImage, SpColorDict, GrowthDict, MaintDict, IndIDs, Qs, IndID, viscosity

    global IndTimeIn, IndExitAge, avgTau, TracerIDs, TracerExitAge, TracerXcoords, TracerYcoords, tracer_scatImage, resource_scatImage
    global ResXcoords, ResYcoords, ResZcoords, ResID, ResIDs, ResVals, alpha, ResTypes, ResUseDict, DispParamsDict

    global one9th, four9ths, one36th, barrierN, barrierS, barrierE, barrierW, barrierNE, barrierNW, barrierSE, barrierSW, sim, RAD, splist
    global BarrierXcoords1, BarrierYcoords1, BarrierXcoords2, BarrierYcoords2, BarrierWidth, BarrierHeight, ct1, Mu, Maint

    global motion, D, reproduction, mutation, predators, parasites, symbionts, env_gradient, J, seedcom, m, r, nr, rmax, avg_prey, avg_symb, avg_parasite
    global N, TracerTau, IndTau, ResDens, ResDiv, ResRich, S, ES, Ev, BP, SD, Nm, sk, Mu, Maint, T, R, seedcom, stop, prod_i, prod_q

    global TracerTimeIn, TracerZcoords, ResTimeIn, ResExitAge, SpeciesIDs, avg_growth, avg_Q, avg_maint, avg_disp, avg_res

    for step in range(1): # adjust number of steps for smooth animation

        seed() # use current system time to initiate a random seed (ensures that autocorrelation doesn't crop-up, as is possible when using pseudorandom number generators)

        # new tracers
        coords = [TracerXcoords, TracerYcoords]
        if D == 3: coords.append(TracerZcoords)

        TracerIDs, TracerTimeIn, coords = bide.NewTracers(TracerIDs, coords, TracerTimeIn, width, height, length, u0, D)

        if D == 2: TracerXcoords, TracerYcoords = coords
        elif D == 3: TracerXcoords, TracerYcoords, TracerZcoords = coords


        # inflow of resources
        coords = [ResXcoords, ResYcoords]
        if D == 3: coords.append(ResZcoords)

        ResTypes, ResVals, coords, ResIDs, ResID, ResTimeIn = bide.ResIn(ResTypes, ResVals, coords, ResID, ResIDs, ResTimeIn, r, rmax, nr, width, height, length, u0, D)

        if D == 2: ResXcoords, ResYcoords = coords
        elif D == 3: ResXcoords, ResYcoords, ResZcoords = coords


	# immigration
        coords = [IndXcoords, IndYcoords]
        if D == 3: coords.append(IndZcoords)

        SpeciesIDs, coords, MaintDict, GrowthDict, DispParamDict, SpColorDict, IDs, ID, TimeIn, Qs, ResUseDict = bide.immigration(m, SpeciesIDs, coords, width, height, length, MaintDict, GrowthDict, DispParamsDict, SpColorDict, IndIDs, IndID, IndTimeIn, Qs, ResUseDict, nr, u0, alpha, D)

        if D == 2: IndXcoords, IndYcoords = coords
        elif D == 3: IndXcoords, IndYcoords, IndZcoords = coords


        if motion == 'fluid' or motion == 'conveyor':  # a 'conveyor' belt action wherein y-coordinates never change will occur when there is no turbulence in a fluid dynamics model, most analogous to an infinitely viscous fluid

            # stream
            nN, nS, nE, nW, nNE, nNW, nSE, nSW, barrier, shift, sign = LBM.stream([nN, nS, nE, nW, nNE, nNW, nSE, nSW, barrier, shift, sign])

            # collide
            rho, ux, uy, n0, nN, nS, nE, nW, nNE, nNW, nSE, nSW = LBM.collide(viscosity, rho, ux, uy, n0, nN, nS, nE, nW, nNE, nNW, nSE, nSW, u0)

            # dispersal
            List = [SpeciesIDs, IndIDs, IndID, Qs]
            SpeciesIDs, IndXcoords, IndYcoords, IndExitAge, IndIDs, IndID, IndTimeIn, Qs = bide.fluid_movement(List, IndTimeIn, IndExitAge, IndXcoords, IndYcoords, ux, uy, width, height, u0)

            # resource flow
            List = [ResTypes, ResIDs, ResID, ResVals]
            ResTypes, ResXcoords, ResYcoords, ResExitAge, ResIDs, ResID, ResTimeIn, ResVals = bide.fluid_movement(List, ResTimeIn, ResExitAge, ResXcoords, ResYcoords, ux, uy, width, height, u0)

            # moving tracer particles
            List = [TracerIDs]
            TracerIDs, TracerXcoords, TracerYcoords, TracerExitAge, TracerTimeIn = bide.fluid_movement(List, TracerTimeIn, TracerExitAge, TracerXcoords, TracerYcoords, ux, uy, width, height, u0)

        elif motion == 'random_walk' or motion == 'uncorrelated':

            # Moving tracer particles
            coords = [TracerXcoords, TracerYcoords]
            if D == 3: coords.append(TracerZcoords)

            Lists = [TracerIDs]
            Lists, ExitAge, TimeIn, coords = bide.nonfluid_movement('tracer', Lists, TracerExitAge, TracerTimeIn, coords, width, height, length, u0, D)
            IDs = Lists

            if D == 2: TracerXcoords, TracerYcoords = coords
            elif D == 3: TracerXcoords, TracerYcoords, TracerZcoords = coords


            # Moving resource particles
            coords = [ResXcoords, ResYcoords]
            if D == 3: coords.append(ResZcoords)

            Lists = [ResTypes, ResIDs, ResVals]
            Lists, ExitAge, TimeIn, coords = bide.nonfluid_movement('resource', Lists, ResExitAge, ResTimeIn, coords, width, height, length, u0, D)
            ResTypes, ResIDs, ResVals = Lists

            if D == 2: Xcoords, Ycoords = coords
            elif D == 3: Xcoords, Ycoords, Zcoords = coords


            # Moving individuals
            coords = [IndXcoords, IndYcoords]
            if D == 3: coords.append(IndZcoords)

            Lists = [SpeciesIDs, IndIDs, Qs, DispParamDict]
            Lists, ExitAge, TimeIn, coords = bide.nonfluid_movement('individual', Lists, IndExitAge, IndTimeIn, coords, width, height, length, u0, D)
            SpeciesIDs, IndIDs, Qs = Lists

            if D == 2: Xcoords, Ycoords = coords
            elif D == 3: Xcoords, Ycoords, Zcoords = coords

        # consume and reproduce
        ResCoords = [ResXcoords, ResYcoords]
        if D == 3: ResCoords.append(ResZcoords)

        IndCoords = [IndXcoords, IndYcoords]
        if D == 3: IndCoords.append(IndZcoords)

        p1 = len(IndIDs)
        q1 = sum(Qs)

        ResLists, IndLists = bide.ConsumeAndReproduce(ResTypes, ResVals, ResIDs, ResID, ResCoords, ResTimeIn, ResExitAge, SpeciesIDs, Qs, IndIDs, IndID, IndTimeIn, IndCoords, width, height, length, GrowthDict, ResUseDict, D)
        ResTypes, ResVals, ResIDs, ResID, ResTimeIn, ResExitAge, ResXcoords, ResYcoords, ResZcoords = ResLists
        SpeciesIDs, Qs,   IndIDs, IndID, IndTimeIn,          IndXcoords, IndYcoords, IndZcoords = IndLists

        prod_i = len(IndIDs) - p1
        prod_q = sum(Qs) - q1

        # maintenance
        coords = [IndXcoords, IndYcoords]
        if D == 3: coords.append(IndZcoords)

        SpeciesIDs, coords, IndExitAge, IndIDs, IndTimeIn, Qs = bide.maintenance(SpeciesIDs, coords, IndExitAge, SpColorDict, MaintDict, IndIDs, IndTimeIn, Qs, D)
        if D == 2: Xcoords, Ycoords = coords
        elif D == 3: Xcoords, Ycoords, Zcoords = coords


    ########## plot the system #################################################
    if D == 3:
        fig.add_subplot(111, projection='3d')
        plt.tick_params(axis='both', which='both', bottom='off', top='off', left='off', right='off', labelbottom='off', labelleft='off')

    else:
        fig.add_subplot(111)
        plt.tick_params(axis='both', which='both', bottom='off', top='off', left='off', right='off', labelbottom='off', labelleft='off')

    if len(SpeciesIDs) >= 1:
        RAD, splist = bide.GetRAD(SpeciesIDs)
        N, S = len(SpeciesIDs), len(RAD)

    else: RAD, splist, N, S = [], [], 0, 0
    Title = ['Inds consume resources, grow, reproduce, and die as they flow through a fluid environment. Average speed',
           '\non the x-axis is '+str(u0)+' units per time step. '+str(len(TracerExitAge))+' tracers have passed through.',
           'N = '+str(N)+', S = '+str(S)+'.'
           '\nOpen circles are resource particles. Semi-impermeable barriers (grey bars) produce turbulence.']

    txt.set_text(' '.join(Title))
    plt.draw()
    plt.ylim(0,height)
    plt.xlim(0,width)

    ##### PLOTTING THE IndS ############################################
    resource_scatImage.remove()
    if D == 2: resource_scatImage = plt.scatter(ResXcoords, ResYcoords, c = 'w', edgecolor = 'SpringGreen', s = ResTypes, lw = 0.6, alpha=0.7)
    elif D == 3: resource_scatImage = plt.scatter(ResXcoords, ResYcoords, ResZcoords, c = 'w', edgecolor = 'SpringGreen', s = ResTypes, lw = 0.6, alpha=0.7)

    tracer_scatImage.remove()
    if D == 2: tracer_scatImage = plt.scatter(TracerXcoords, TracerYcoords, c = 'r', marker='*', lw=0.0, s = 200, alpha=0.6)
    elif D == 3: tracer_scatImage = plt.scatter(TracerXcoords, TracerYcoords, TracerZcoords, c = 'r', marker='*', lw=0.0, s = 200, alpha=0.6)

    Ind_scatImage.remove()
    colorlist = []

    for i, val in enumerate(SpeciesIDs): colorlist.append(SpColorDict[val])
    if D == 2: Ind_scatImage = plt.scatter(IndXcoords, IndYcoords, c = colorlist, edgecolor = '0.2', s = Qs, lw = 0.2, alpha=0.9)
    elif D == 3: Ind_scatImage = plt.scatter(IndXcoords, IndYcoords, IndZcoords, c = colorlist, edgecolor = '0.2', s = Qs, lw = 0.2, alpha=0.9)

    # Record model values and reset, or not
    if len(TracerExitAge) >= stop:

        # Examining the resource RAD
        if len(ResTypes) > 0:
            ResRAD, Rlist = bide.GetRAD(ResTypes)
            ResDens = sum(ResTypes)/(height*width)
            ResDiv = float(metrics.Shannons_H(ResRAD))
            ResRich = len(Rlist)

        # Residence times for tracers and Inds
        TracerTau = float(np.mean(TracerExitAge))
        IndTau = float(np.mean(IndExitAge))

        T = len(TracerIDs)
        R = len(ResTypes)

        N = len(SpeciesIDs)
        if N >= 1:

            RAD, splist = bide.GetRAD(SpeciesIDs)
            RAD, splist = zip(*sorted(zip(RAD, splist), reverse=True))
            S = len(RAD)

            # Specific Growth rate and Maintenance

            mu, maint = 0, 0
            for i, sp in enumerate(splist):
                mu = RAD[i] * GrowthDict[sp]
                maint = RAD[i] * MaintDict[sp]

            Mu = mu/N
            Maint = maint/N

            # Evenness, Dominance, and Rarity measures
            Ev = float(metrics.e_var(RAD))
            ES = float(metrics.e_simpson(RAD))
            Nm = max(RAD)
            BP = float(Nm/N)
            SD = float(metrics.simpsons_dom(RAD))
            sk = float(stats.skew(RAD))

        process = psutil.Process(os.getpid())
        mem = round(process.get_memory_info()[0] / float(2 ** 20), 1)    # return the memory usage in MB

        print sim, ' N:', N, 'S:', S, ' pI:', round(prod_i,1), 'pQ:', round(prod_q,2), ': flow:', u0, ' MB:',mem

        SString = str(splist).strip('()')
        RADString = str(RAD).strip('()')
        OUT1 = open(mydir + '/GitHub/hydrobide/results/simulated_data/SimData.csv','a')
        OUT2 = open(mydir + '/GitHub/hydrobide/results/simulated_data/RADs.csv','a')
        OUT3 = open(mydir + '/GitHub/hydrobide/results/simulated_data/Species.csv','a')
        print>>OUT1, ct1,',', sim,',', prod_i,',', prod_q,',', r,',', nr,',', rmax,',', BarrierWidth,',', BarrierHeight,',', alpha,',', seedcom,',', stop,',', u0,',', width,',', height,',', viscosity,',', N,',', m,',', TracerTau,',', IndTau,',', ResDens,',', ResDiv,',', ResRich,',', S,',', ES,',', Ev,',', BP,',', SD,',', Nm,',', sk,',', Mu,',', Maint
        print>>OUT2, RADString
        print>>OUT3, SString
        OUT1.close()
        OUT2.close()
        OUT3.close()


        if u0 == min(Rates):
            SpColorDict, GrowthDict, MaintDict = {}, {}, {}
            ResUseDict, ResColorDict, DispParamsDict = {}, {}, {}
            width, height, length, alpha, motion, D, reproduction, mutation, predators, parasites, symbionts, env_gradient, J, seedcom, m, r, nr, rmax, avg_prey, avg_symb, avg_parasite, avg_growth, avg_Q, avg_maint, avg_disp, avg_res = get_rand_params()
            sim += 1
            alpha = np.random.uniform(0.9, 0.999)
            print '\n'

        Rates = np.roll(Rates, -1, axis=0)
        u0 = Rates[0]  # initial in-flow speed

        TracerTau, IndTau, ResDens, ResDiv, ResRich, S, ES, Ev, BP, SD, Nm, sk, Mu, Maint = [0,0,0,0,0,0,0,0,0,0,0,0,0,0]

        IndTimeIn,SpeciesIDs,IndXcoords, IndYcoords, TracerXcoords, TracerYcoords, RES, ResXcoords, ResYcoords, ResIDs, ResTypes, IndIDs, Qs, IndExitAge, TracerExitAge, TracerIDs = [list([]) for _ in xrange(16)]

        if motion == 'fluid' or motion == 'conveyor':
            # Lattice Boltzmann PARAMETERS
            n0, nN, nS, nE, nW, nNE, nNW, nSE, nSW, barrier, rho, ux, uy, barrierN, barrierS, barrierE, barrierW, barrierNE, barrierNW, barrierSE, barrierSW, BarrierXcoords1, BarrierYcoords1, BarrierXcoords2, BarrierYcoords2 = LBM.SetLattice(u0, viscosity, width, height, BarrierWidth, BarrierHeight, BarrierXcoords1, BarrierYcoords1, BarrierXcoords2, BarrierYcoords2)

        # Seed or do not seed the community ############################################
        if seedcom > 0:
            # inflow of resources
            coords = [ResXcoords, ResYcoords]
            if D == 3: coords.append(ResZcoords)

            ResTypes, ResVals, coords, ResIDs, ResID, ResTimeIn = bide.ResIn(ResTypes, ResVals, coords, ResID, ResIDs, ResTimeIn, r, rmax, nr, width, height, length, u0, D)

            if D == 2: ResXcoords, ResYcoords = coords
            elif D == 3: ResXcoords, ResYcoords, ResZcoords = coords

            # immigration
            coords = [IndXcoords, IndYcoords]
            if D == 3: coords.append(IndZcoords)

            SpeciesIDs, coords, MaintDict, GrowthDict, DispParamDict, SpColorDict, IDs, ID, TimeIn, Qs, ResUseDict = bide.immigration(m, SpeciesIDs, coords, width, height, length, MaintDict, GrowthDict, DispParamsDict, SpColorDict, IndIDs, IndID, IndTimeIn, Qs, ResUseDict, nr, u0, alpha, D)

            if D == 2: IndXcoords, IndYcoords = coords
            elif D == 3: IndXcoords, IndYcoords, IndZcoords = coords

        ####################### REPLACE ENVIRONMENT
        fig.add_subplot(1, 1, 1)

        tracer_scatImage.remove()
        tracer_scatImage = plt.scatter([0],[0], alpha=0.0)

        resource_scatImage.remove()
        resource_scatImage = plt.scatter([0],[0], alpha=0.0)

        Ind_scatImage.remove()
        Ind_scatImage = plt.scatter([0],[0], alpha=0.0)

        ########## plot the system #############################################
        if D == 3:
            fig.add_subplot(111, projection='3d')
            plt.tick_params(axis='both', which='both', bottom='off', top='off', left='off', right='off', labelbottom='off', labelleft='off')

        else:
            fig.add_subplot(1, 1, 1)  # Plot 1:
            plt.tick_params(axis='both', which='both', bottom='off', top='off', left='off', right='off', labelbottom='off', labelleft='off')




############## OPEN OUTPUT DATA FILE ###########################################
OUT1 = open(mydir + '/GitHub/hydrobide/results/simulated_data/SimData.csv','w+')
OUT2 = open(mydir + '/GitHub/hydrobide/results/simulated_data/RADs.csv','w+')
OUT3 = open(mydir + '/GitHub/hydrobide/results/simulated_data/Species.csv','w+')
# printing physical variables, residence times, community diversity properties, physiological values, trait values, resource values
print>>OUT1, 'RowID, sim, ind.prod, biomass.prod, res.inflow, res.types, max.res, barrier.width, barrier.height, logseries.a, starting.seed, stop.point, FlowRate, Width, Height, Viscosity, N, immigration.rate, particle.tau, cell.tau, resource.concentration, shannons.resource.diversity, resource.richness, S, simpson.e, e.var, berger.parker, inv.simp.D, N.max, skew, avg.per.capita.growth, avg.per.capita.maint'
#             ct1,   sim, prod_i,   prod_q,       r,          nr,        rmax,    BarrierWidth,  BarrierHeight,  alpha,       seedcom,          stop,       u0,       width, height, viscosity, N, m,                TracerTau,    IndTau,ResDens,               ResDiv,                      ResRich,           S, ES,        Ev,    BP,            SD,         Nm,    sk,   Mu,                    Maint
OUT1.close()
OUT2.close()
OUT3.close()

################ DIMENSIONAL & MODEL CONSTANTS ##################################
width, height, length, alpha, motion, D, reproduction, mutation, predators, parasites, symbionts, env_gradient, J, seedcom, m, r, nr, rmax, avg_prey, avg_symb, avg_parasite, avg_growth, avg_Q, avg_maint, avg_disp, avg_res = get_rand_params()

#######################  Ind COMMUNITY PARAMETERS  #########################
IndID, ResID, N, S, ct1, Mu, Maint, T, R, prod_i, prod_q = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
N, TracerTau, IndTau, ResDens, ResDiv, ResRich, S, ES, Ev, BP, SD, Nm, sk, Mu, Maint = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

RAD, splist = [], []
IndIDs, Qs, IndExitAge, IndTimeIn, SpeciesIDs, IndXcoords, IndYcoords, IndZcoords,  = [], [], [], [], [], [], [], []
ResIDs, ResVals, ResExitAge, ResTimeIn, ResTypes, ResYcoords, ResXcoords, ResZcoords = [], [], [], [], [], [], [], []
TracerIDs, TracerExitAge, TracerTimeIn, TracerXcoords, TracerYcoords, TracerZcoords,  = [], [], [], [], [], []

SpColorDict, GrowthDict, MaintDict = {}, {}, {}
ResUseDict, ResColorDict, DispParamsDict = {}, {}, {}

###############  SIMULATION VARIABLES, DIMENSIONAL & MODEL CONSTANTS  ##########
stop, shift, sign, sim, BarrierWidth, BarrierHeight = 10, 0.0, 0.1, 0, 0.0, 0.0
BarrierXcoords1, BarrierYcoords1, BarrierXcoords2, BarrierYcoords2 = [[],[],[],[]]
viscosity = 1 # unitless but required by an LBM model

Rates = np.array([1.0, 0.75, 0.5, 0.1, 0.075, 0.05, 0.025, 0.01])  # inflow speeds
u0 = Rates[0]  # initial in-flow speed


############### INITIALIZE GRAPHICS ############################################
fig = plt.figure(figsize=(12, 8))

if D == 2:
    fig.add_subplot(111) # initiate first plot

    Ind_scatImage = plt.scatter([0],[0], alpha=0.0)
    tracer_scatImage = plt.scatter([0],[0], alpha=0.0)
    resource_scatImage = plt.scatter([0],[0], alpha=0.0)

    if motion == 'fluid' or motion == 'conveyor':

        #####################  Lattice Boltzmann PARAMETERS  ###########################
        n0, nN, nS, nE, nW, nNE, nNW, nSE, nSW, barrier, rho, ux, uy, barrierN, barrierS, barrierE, barrierW, barrierNE, barrierNW, barrierSE, barrierSW, BarrierXcoords1, BarrierYcoords1, BarrierXcoords2, BarrierYcoords2 = LBM.SetLattice(u0, viscosity, width, height, BarrierWidth, BarrierHeight, BarrierXcoords1, BarrierYcoords1, BarrierXcoords2, BarrierYcoords2)

        left = BarrierXcoords1[0]
        bottom = BarrierYcoords1[0]
        BHeight = BarrierYcoords1[1] - bottom
        BWidth = BarrierXcoords1[1] - left
        BarrierImage1 = plt.bar(left-0.3, BHeight, BWidth-0.3, bottom,
                                color = '0.3', edgecolor = '0.4', alpha=0.2)

        left = BarrierXcoords2[0]
        bottom = BarrierYcoords2[0]
        BHeight = BarrierYcoords2[1] - bottom
        BWidth = BarrierXcoords2[1] - left
        BarrierImage2 = plt.bar(left-0.3, BHeight, BWidth-0.3, bottom,
                                color = '0.3', edgecolor = '0.4', alpha=0.2)

elif D == 3:
    fig.add_subplot(111, projection='3d')

    Ind_scatImage = plt.scatter([0],[0],[0], alpha=0.0)
    tracer_scatImage = plt.scatter([0],[0],[0], alpha=0.0)
    resource_scatImage = plt.scatter([0],[0],[0], alpha=0.0)

    plt.tick_params(axis='both', which='both', bottom='off', top='off', left='off', right='off', labelbottom='off', labelleft='off')


# Seed or do not seed the community ############################################
if seedcom > 0:
    # inflow of resources
    coords = [ResXcoords, ResYcoords]
    if D == 3: coords.append(ResZcoords)

    ResTypes, ResVals, coords, ResIDs, ResID, ResTimeIn = bide.ResIn(ResTypes, ResVals, coords, ResID, ResIDs, ResTimeIn, r, rmax, nr, width, height, length, u0, D)

    if D == 2: ResXcoords, ResYcoords = coords
    elif D == 3: ResXcoords, ResYcoords, ResZcoords = coords


    # immigration
    coords = [IndXcoords, IndYcoords]
    if D == 3: coords.append(IndZcoords)

    SpeciesIDs, coords, MaintDict, GrowthDict, DispParamDict, SpColorDict, IDs, ID, TimeIn, Qs, ResUseDict = bide.immigration(m, SpeciesIDs, coords, width, height, length, MaintDict, GrowthDict, DispParamsDict, SpColorDict, IndIDs, IndID, IndTimeIn, Qs, ResUseDict, nr, u0, alpha, D)

    if D == 2: IndXcoords, IndYcoords = coords
    elif D == 3: IndXcoords, IndYcoords, IndZcoords = coords

Title = [' ',' ']
txt = fig.suptitle(' '.join(Title), fontsize = 12)

ani = animation.FuncAnimation(fig, nextFrame, frames=5000, interval=100, blit=False) # 20000 frames is a long movie
plt.show()
#ani.save(mydir+'/Hydro-bide/results/movies/HydrobideVideoTest.avi', metadata={'artist':'Guido'}, bitrate=5000)