# VA4MR-visual-odometry-project

Readme of the project of Roberto Pellerito, Giacomo Manzoni and Lorenzo Piglia

In order to run correctly the Vo run main.m:

Change dataset as usual by changing ds
Parameters are retrieved with get params
To enable the additional feature you will find a boolean variable
'EnableScaling' with a true value if enable a false if not enable.
Once you activate it you have to wait until the right time for the scaling to have effects.
For malaga and kitty, once the code finds the car it will eventually
recompute the trajectory in world frame, in metric scale, and it returns back by some units.
While this is not visually appealing it is not going suddenly back,
the additional line is due to line connecting new pose and last
unscaled pose

Hardware: MacBook pro with arm processor (M1), 16 gb ram
	  Windows 10 with i5, 8 gb ram
