# Developer Notes

## Overview of the Architecture

The following is an overview of the entire ecosystem, where **Yao** and **CuYao**
are two meta-packages.

![stack](../assets/images/stack.png)

## The role of QBIR

Currently the main functionality is built on the Quantum Block Intermediate Representation (QBIR).
A quantum program is defined by QBIR and then interpreted to different targets, such as different
simulation backend or matrix representation.

![framework](../assets/images/YaoFramework.png)
