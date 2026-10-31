[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://workshop-matlab.mathworks.com/open/github/v1?repo=Brenda-MW/DesignForEveryEar)

# MATLAB Expo Online Hands-On Workshop
**Designing for Every Ear: Engineering Hearing Assistive Tech for Edge Compute**

This repository contains the exercise files for designing hearing assistive technology in MATLAB and Simulink. The three exercises go from simulating hearing loss, to building and verifying a cochlear implant processor using Model-Based Design (MBD), to compressing an AI model to fit a hearing device.

## Hardware and Software Requirements
To participate in the workshop, you need:
1. A laptop
2. Google Chrome browser
3. A MathWorks account

You will be provided with a temporary MATLAB workshop license that will give you access to all products used in the workshop, as well as the workshop exercise files.

MATLAB Online sessions are temporary. Save any work you want to keep to MATLAB Drive.

## Continue After the Workshop
The workshop license expires after the event. To keep working on the exercises, you need a license that includes the products below.

| Exercise | Products |
|---|---|
| 1. Experience hearing loss | MATLAB, Audio Toolbox, Signal Processing Toolbox |
| 2. Cochlear implant processor | Simulink, DSP System Toolbox, Requirements Toolbox, Simulink Test, MATLAB Coder, Simulink Coder, Embedded Coder |
| 3. Shrink AI to fit the device | Deep Learning Toolbox, Deep Learning Toolbox Model Quantization Library, Audio Toolbox |


## AI Tutor
The `Knowledge/Guide.md` file sets up an AI coding agent as a tutor for the exercises. The agent runs MATLAB experiments to help you explore each exercise further. 

Review and test any code the agent generates before relying on it.
### Set Up the AI Tutor
In the workshop, the AI coding agent connects to MATLAB through the MATLAB MCP Core Server and uses the MATLAB and Simulink agentic toolkits. To use the tutor in your own environment:

1. Install an AI coding agent that supports the Model Context Protocol (MCP), such as Codex CLI or Claude Code.
2. Install the [MATLAB MCP Core Server](https://github.com/matlab/matlab-mcp-core-server) and register it with your agent, following the instructions in its repository.
3. Install the MATLAB and Simulink agentic toolkits.
4. Open the agent in the root folder of this repository, and point it to `Knowledge/Guide.md` as its instructions file.

## References
- **Exercise 1** is adapted from the Hearing Loss Simulation Plugin by Angeliki Mourgela (Queen Mary University of London and BBC R&D), [MATLAB File Exchange 79541](https://www.mathworks.com/matlabcentral/fileexchange/79541). The processing was extracted from the original `audioPlugin` into a standalone function.
- **Exercise 2** is adapted from MathWorks shipping example: [Cochlear Implant Speech Processor](https://www.mathworks.com/help/dsp/ug/cochlear-implant-speech-processor.html).
- **Exercise 3** is adapted from MathWorks shipping examples, including [Speaker Recognition Using x-vectors](https://www.mathworks.com/help/deeplearning/ug/speaker-recognition-using-x-vectors.html).

## Feedback
Thank you for joining us in the workshop. If you find a problem with the exercise files or have a suggestion, please open an issue in the [Issues](https://github.com/Brenda-MW/DesignForEveryEar/issues) tab of this repository.
