# Racer Movement Experimentation

*Absolutely unhinged* experimentation with movement mechanics for racing games.
It's 2D, but presumably these mechanics could be made to work in 3D with some effort.

I've tried to make sure that the maths is right in that nothing breaks as you approach dt = 0 and that the units are consistent (with a few constants that convert between units (like what the gravitational constant does) assumed).
I haven't really tested anything, though. Heh.

All variables on the machine related to movement are either vectors or scalars, no booleans or state enums.
If one wants a boost state, then they should code in a boost amount variable which increases to enter boost state and decreases to exit it. That sort of thing.

Shifting left or right is not implemented. Not sure how I would have added that in a way I find satisfactory, seeing that the engine accelerator can be rotated left or right a bit, which kinda achieves that job?

Changing the control of the machine (changing your inputs) lowers its performance slightly.
Why? So that it's better to set the machine's controls to mid-range values rather than go between zero and maximum when a mid-range effect is desired. Well, since keyboard input is the only option, you can't actually do that. But if you could... then it would mean a turn that requires 50% max angular speed would be best executed with a careful 50% control stick push.

Turning also lowers performance.
Lowered performance reduces acceleration and max speed.
You never actually reach max speed because your terminal velocity due to drag is always below it, because your acceleration—which pushes against drag—drops off as you approach max speed.

Why all this?
For my own enjoyment. I like working with complex and highly mathematical stuff like this.

Is it usable for real racing games?
Probably not!
I ought to experiment again at some point.
