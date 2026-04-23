# Radar-Detector

## Project Details
#### a fully open-source radar detector that can be easily replicated by others. Unlike existing commercial solutions, which are proprietary, this design will provide transparency, customization, and accessibility to users. By creating the first truly open-source radar detector, the project expands available options for individuals interested in building, modifying, or better understanding radar detection technology.
#### This device is powered by the 12V port that's in every commercial vehicle by using a 5V adapter and USB-C connector on board.

## Current State
#### The current Design includes
#### - Completed RF and Control Board
#### - Completed Antenna and Waveguide
#### - A breadboarded circuit for K band detection

## Semester End Report
#### For the Enterprise Program at Michigan Tech there is a end of semester report for the project to summarize the progress of the project. [Link](https://docs.google.com/document/d/1saLg0oObQiK9GF-1CGu6zWZuvDCvK0RMIuFfh2jqqCw/edit?usp=sharing)

## Relevant Standards
#### - Traces Were sized appropriately for current being drawn
#### - No traces can be ran under the main RF lines
#### - There was fusing put in front of the main power input from the USB-C
#### - Decoupling capacitors used to reduce noise from voltage sources going into sensitive components

## Constraints of Design
#### - when working with high frequencies up to 40GHz you have to use special small components that can handle it
#### - The material to make a PCB that can handle that high of frequencies is very expensive
#### - Amplifiers for this frequency are very expensive

## Next Semester Goals
#### - Look into possible cheaper solutions using modules like what we found for the K band
#### - Test the Ka band implementation once we have the antenna
#### - Look into the design on the component for the K band and see if parts of it are re-creatable