View.Set ("offscreenonly")
const r := 75               %radius of the circle
const c := 2 * 3.14 * r     %circumference of the circle
const spd := 5              %speed of the dot moving around the circle (pixels per cycle)
const cx := maxx div 2     %center of the circle (x coordinate)
const cy := maxy div 2     %center of the circle (y coordinate)
var auto := true
var angle, x, y : real
angle := 0                 %starting angle. 0/360 = right, 90 = top, 180 = left, 270 = bottom

procedure setXY
    if auto then
	angle += (360 * (spd / c))
    end if
    x := r * cosd (angle) + cx              %get x coordinate from polar coordinates
    y := r * sind (angle) + cy              %get y coordinate from polar coordinates
end setXY

var toggleDelay := 250
procedure keyPresses
    var chars : array char of boolean
    Input.KeyDown (chars)
    if chars (KEY_UP_ARROW) and auto = false then       %if the up arrow is being pressed and the dot is not circling automaticly
	angle += (360 * (spd / c))                      %increase the angle based on the speed
    end if
    if chars (KEY_DOWN_ARROW) and auto = false then
	angle -= (360 * (spd / c))                      %decrease the angle based on the speed
    end if
    if chars (KEY_ENTER) and toggleDelay <= 0 then      %if the enter key is being pressed and it has been at least 250ms since it was last pressed
	if auto then
	    auto := false
	    toggleDelay := 250
	else
	    auto := true
	    toggleDelay := 250
	end if
    end if
    toggleDelay -= 30
end keyPresses

procedure draw
    cls
    Draw.Oval (cx, cy, r, r, black)
    Draw.FillOval (cx, cy, 2, 2, black)
    Draw.FillOval (round (x), round (y), 5, 5, green)
    %------debug------
    Draw.Line (0, cy, maxx, cy, red)
    Draw.Line (cx, 0, cx, maxy, red)
    Draw.Line (0, round (y), maxx, round (y), blue)
    Draw.Line (round (x), 0, round (x), maxy, blue)

    Draw.Line (cx, cy, round (x), round (y), green)
    Draw.Arc (cx, cy, r div 4 * 3, r div 4 * 3, 0, round (angle), green)

    put "Circumference = ", c
    locate (1, 25)
    put "Speed = ", spd
    locate (1, 50)
    put "Radius = ", r
    put "Angle = ", angle
    locate (2, 25)
    put "(x,y) = (", round (x), ",", round (y), ")"
    locate (2, 50)
    put "Time to circle = ", ((c / spd) * 30) / 1000, "s"
    put "Press <Enter> to toggle between auto spin and manual modes.  Mode = " ..
    if auto then
	put "Auto"
    else
	put "Manual"
    end if
    View.Update
end draw

loop
    keyPresses
    if angle >= 360 then
	angle -= 360
    end if
    if angle < 0 then
	angle += 360
    end if
    setXY
    draw
    Time.DelaySinceLast (30)
end loop
