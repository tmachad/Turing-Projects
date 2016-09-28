const G := 0.001 %0.00000000006674
const fps := 30

class object
    import fps
    export var x, var y, var xVel, var yVel, var mass, var size, var mobile, var clr, move, accelerate, draw

    var x, y, xVel, yVel, mass : real
    var size, clr : int
    var mobile : boolean

    procedure move (tmpx, tmpy : real, relative : boolean)
	if relative then
	    x += tmpx
	    y += tmpy
	else
	    x := tmpx
	    y := tmpy
	end if
    end move

    procedure accelerate (accel, angle : real)
	xVel += cosd (angle) * accel
	yVel += sind (angle) * accel
    end accelerate

    procedure draw
	Draw.FillOval (round (x), round (y), size, size, clr)
    end draw
end object

var objects : flexible array 1 .. 0 of pointer to object

procedure createObject (x, y, xVel, yVel, mass : real, clr : int, mobile : boolean)
    new objects, upper (objects) + 1
    new object, objects (upper (objects))
    objects (upper (objects)) -> x := x
    objects (upper (objects)) -> y := y
    objects (upper (objects)) -> xVel := xVel
    objects (upper (objects)) -> yVel := yVel
    objects (upper (objects)) -> mass := mass
    objects (upper (objects)) -> size := round (((3 * mass) / (12.566)) ** (1 / 3))
    if objects (upper (objects)) -> size < 2 then
	objects (upper (objects)) -> size := 2
    end if
    objects (upper (objects)) -> clr := clr
    objects (upper (objects)) -> mobile := mobile
end createObject

class meteor
    export var x, var y, var xVel, var yVel, var mass, var size, accelerate, move, draw

    var x, y, xVel, yVel, mass : real
    var size : int

    procedure accelerate (accel, angle : real)
	xVel += cosd (angle) * accel
	yVel += sind (angle) * accel
    end accelerate

    procedure move (tmpX, tmpY : real, relative : boolean)
	if relative then
	    x += tmpX
	    y += tmpY
	else
	    x := tmpX
	    y := tmpY
	end if
    end move

    procedure draw
	Draw.FillOval (round (x), round (y), size, size, brown)
    end draw
end meteor

var meteors : flexible array 1 .. 0 of pointer to meteor

procedure createMeteor (x, y, xVel, yVel, mass : real)
    new meteors, upper (meteors) + 1
    new meteor, meteors (upper (meteors))
    meteors (upper (meteors)) -> x := x
    meteors (upper (meteors)) -> y := y
    meteors (upper (meteors)) -> xVel := xVel
    meteors (upper (meteors)) -> yVel := yVel
    meteors (upper (meteors)) -> mass := mass
    meteors (upper (meteors)) -> size := round (mass * 2)
end createMeteor

procedure killMeteor (met : int)
    for i : met .. upper (meteors) - 1
	meteors (i) := meteors (i + 1)
    end for
    new meteors, upper (meteors) - 1
end killMeteor

function findAngle (x1, y1, x2, y2 : real) : real               %x1,y1 is the origin, x2,y2 is the destination
    if x2 > x1 and y2 = y1 then
	result 0
    elsif x2 = x1 and y2 > y1 then
	result 90
    elsif x2 < x1 and y2 = y1 then
	result 180
    elsif x2 = x1 and y2 < y1 then
	result 270
    elsif x2 < x1 then
	result arctand ((y2 - y1) / (x2 - x1)) + 180
    elsif x2 not= x1 then
	result arctand ((y2 - y1) / (x2 - x1))
    else
	result 0
    end if
end findAngle

var fx, fy, lx, ly, mx, my, mbtn : int := 0
var aimAngle : real
procedure findLaunchPos
    var tmpAngle : real
    if mx > fx then
	tmpAngle := abs (aimAngle)
    else
	tmpAngle := abs (aimAngle - 180)
    end if
    if mx < maxx and mx > 0 and my < maxy and my > 0 then
	if aimAngle < findAngle (0, maxy, fx, fy) and aimAngle > -90 then               %-90 to top left corner
	    lx := fx - round ((sind (90 - tmpAngle) * (maxy - fy)) / sind (tmpAngle))
	    ly := maxy
	elsif aimAngle < 0 and aimAngle > findAngle (0, maxy, fx, fy) then              %top left corner to 0
	    lx := 0
	    ly := fy + round ((sind (tmpAngle) * fx) / sind (90 - tmpAngle))
	elsif aimAngle > 0 and aimAngle < findAngle (0, 0, fx, fy) then                 %0 to bottom left corner
	    lx := 0
	    ly := fy - round ((sind (tmpAngle) * fx) / sind (90 - tmpAngle))
	elsif aimAngle > findAngle (0, 0, fx, fy) and aimAngle < 90 then                %bottom left corner to 90
	    lx := fx - round ((sind (90 - tmpAngle) * fy) / sind (tmpAngle))
	    ly := 0
	elsif aimAngle > 90 and aimAngle < findAngle (maxx, 0, fx, fy) then             %90 to bottom right corner
	    lx := fx + round ((sind (90 - tmpAngle) * fy) / sind (tmpAngle))
	    ly := 0
	elsif aimAngle > findAngle (maxx, 0, fx, fy) and aimAngle < 180 then            %bottom right corner to 180
	    lx := maxx
	    ly := fy - round ((sind (tmpAngle) * (maxx - fx)) / sind (90 - tmpAngle))
	elsif aimAngle > 180 and aimAngle < findAngle (maxx, maxy, fx, fy) then         %180 to top right corner
	    lx := maxx
	    ly := fy + round ((sind (tmpAngle) * (maxx - fx)) / sind (90 - tmpAngle))
	elsif aimAngle > findAngle (maxx, maxy, fx, fy) and aimAngle < 270 then         %top right corner to 270
	    lx := fx + round ((sind (90 - tmpAngle) * (maxy - fy)) / sind (tmpAngle))
	    ly := maxy
	end if
    end if
end findLaunchPos

var aiming : boolean := false
procedure mouseInput
    Mouse.Where (mx, my, mbtn)
    if mbtn = 1 and aiming = false then
	fx := mx
	fy := my
	aiming := true
    elsif mbtn = 0 and aiming then
	%createMeteor (lx, ly, cosd (aimAngle) * 10, sind (aimAngle) * 10, 1)
	createObject (lx, ly, cosd (aimAngle) * 10, sind (aimAngle) * 10, 1000, brown,true)
	aiming := false
    end if
    if mbtn = 1 then
	aimAngle := findAngle (fx, fy, mx, my)
	findLaunchPos
    end if
end mouseInput

procedure gravitation
    for obj1 : 1 .. upper (objects)             %obj1 is the object that is moving
	for obj2 : 1 .. upper (objects)         %obj2 is the object that is pulling obj1
	    if obj1 not= obj2 and objects (obj1) -> mobile then
		objects (obj1) -> accelerate (G * objects (obj2) -> mass / Math.Distance (objects (obj1) -> x, objects (obj1) -> y, objects (obj2) -> x, objects (obj2) -> y) ** 2,
		    findAngle (objects (obj1) -> x, objects (obj1) -> y, objects (obj2) -> x, objects (obj2) -> y))
	    end if
	end for
	for met : 1 .. upper (meteors)
	    meteors (met) -> accelerate (G * objects (obj1) -> mass / Math.Distance (objects (obj1) -> x, objects (obj1) -> y, meteors (met) -> x, meteors (met) -> y) ** 2,
		findAngle (meteors (met) -> x, meteors (met) -> y, objects (obj1) -> x, objects (obj1) -> y))
	end for
    end for
end gravitation

procedure moveObjects
    for i : 1 .. upper (objects)
	if objects (i) -> mobile then
	    objects (i) -> move (objects (i) -> xVel, objects (i) -> yVel, true)
	end if
    end for
    for i : 1 .. upper (meteors)
	meteors (i) -> move (meteors (i) -> xVel, meteors (i) -> yVel, true)
    end for
end moveObjects


type colData :
    record
	obj1, obj2 : int
    end record

var colCat : flexible array 1 .. 0 of colData
function collided (obj1, obj2 : int) : boolean
    for i : 1 .. upper (colCat)
	if (colCat (i).obj1 = obj1 and colCat (i).obj2 = obj2) or (colCat (i).obj1 = obj2 and colCat (i).obj2 = obj1) then
	    result true
	end if
    end for
    result false
end collided

procedure collisions
    var met : int
    var xVel, yVel, angle1, angle2, cA : real

    for obj1 : 1 .. upper (objects)
	for obj2 : 1 .. upper (objects)
	    if obj1 not= obj2 and Math.Distance (objects (obj1) -> x, objects (obj1) -> y, objects (obj2) -> x, objects (obj2) -> y) <= objects (obj1) -> size + objects (obj2) -> size
		    and collided (obj1, obj2) = false then
		cA := findAngle (objects (obj1) -> x, objects (obj1) -> y, objects (obj2) -> x, objects (obj2) -> y)
		angle1 := findAngle (objects (obj1) -> x, objects (obj1) -> y, objects (obj1) -> x + objects (obj1) -> xVel, objects (obj1) -> y + objects (obj1) -> yVel)
		angle2 := findAngle (objects (obj2) -> x, objects (obj2) -> y, objects (obj2) -> x + objects (obj2) -> xVel, objects (obj2) -> y + objects (obj2) -> yVel)
		xVel := objects (obj1) -> xVel
		yVel := objects (obj1) -> yVel
		objects (obj1) -> xVel := ((objects (obj1) -> xVel * cosd (angle1 - cA) * (objects (obj1) -> mass - objects (obj2) -> mass) + 2 * objects (obj2) -> mass * objects (obj2) -> xVel *
		    cosd (angle2 - cA)) / (objects (obj1) -> mass + objects (obj2) -> mass)) * cosd (cA) + objects (obj1) -> xVel * sind (angle1 - cA) * cosd (cA + (3.14 / 2))
		objects (obj1) -> yVel := ((objects (obj1) -> yVel * cosd (angle1 - cA) * (objects (obj1) -> mass - objects (obj2) -> mass) + 2 * objects (obj2) -> mass * objects (obj2) -> yVel *
		    cosd (angle2 - cA)) / (objects (obj1) -> mass + objects (obj2) -> mass)) * sind (cA) + objects (obj1) -> yVel * sind (angle1 - cA) * sind (cA + (3.14 / 2))

		objects (obj2) -> xVel := ((objects (obj2) -> xVel * cosd (angle2 - cA) * (objects (obj2) -> mass - objects (obj1) -> mass) + 2 * objects (obj1) -> mass * xVel * cosd (angle1 - cA))
		    / (objects (obj2) -> mass + objects (obj1) -> mass)) * cosd (cA) + objects (obj2) -> xVel * sind (angle2 - cA) * cosd (cA + (3.14 / 2))
		objects (obj2) -> yVel := ((objects (obj2) -> yVel * cosd (angle2 - cA) * (objects (obj2) -> mass - objects (obj1) -> mass) + 2 * objects (obj1) -> mass * yVel * cosd (angle1 - cA))
		    / (objects (obj2) -> mass + objects (obj1) -> mass)) * sind (cA) + objects (obj2) -> yVel * sind (angle2 - cA) * sind (cA + (3.14 / 2))
		new colCat, upper (colCat) + 1
		colCat (upper (colCat)).obj1 := obj1
		colCat (upper (colCat)).obj2 := obj2
	    end if
	end for

	met := 0
	loop
	    met += 1
	    exit when met > upper (meteors)
	    if Math.DistancePointLine (objects (obj1) -> x, objects (obj1) -> y, meteors (met) -> x, meteors (met) -> y, meteors (met) -> x + meteors (met) -> xVel,
		    meteors (met) -> y + meteors (met) -> yVel) <= objects (obj1) -> size + meteors (met) -> size then
		objects (obj1) -> xVel := (objects (obj1) -> mass * objects (obj1) -> xVel + meteors (met) -> mass * meteors (met) -> xVel) / (objects (obj1) -> mass + meteors (met) -> mass)
		objects (obj1) -> yVel := (objects (obj1) -> mass * objects (obj1) -> yVel + meteors (met) -> mass * meteors (met) -> yVel) / (objects (obj1) -> mass + meteors (met) -> mass)
		killMeteor (met)
	    end if
	end loop
    end for
    new colCat, 0
end collisions

const timeFrame := 10   %length of the prediction line in seconds (e.g. "timeFrame" seconds into the future)
procedure showPath
    var tmpObjects : array 1 .. upper (objects) of pointer to object
    for i : 1 .. upper (tmpObjects)
	new object, tmpObjects (i)
	tmpObjects (i) -> x := objects (i) -> x
	tmpObjects (i) -> y := objects (i) -> y
	tmpObjects (i) -> xVel := objects (i) -> xVel
	tmpObjects (i) -> yVel := objects (i) -> yVel
	tmpObjects (i) -> mass := objects (i) -> mass
	tmpObjects (i) -> mobile := objects (i) -> mobile
	tmpObjects (i) -> clr := objects (i) -> clr
    end for

    for j : 1 .. timeFrame * fps
	gravitation
	collisions
	moveObjects
	for i : 1 .. upper (objects)
	    Draw.Line (round (objects (i) -> x), round (objects (i) -> y),
		round (objects (i) -> x + objects (i) -> xVel), round (objects (i) -> y + objects (i) -> yVel), objects (i) -> clr)
	end for
    end for

    for i : 1 .. upper (tmpObjects)
	objects (i) -> x := tmpObjects (i) -> x
	objects (i) -> y := tmpObjects (i) -> y
	objects (i) -> xVel := tmpObjects (i) -> xVel
	objects (i) -> yVel := tmpObjects (i) -> yVel
	objects (i) -> mass := tmpObjects (i) -> mass
	objects (i) -> mobile := tmpObjects (i) -> mobile
	objects (i) -> clr := tmpObjects (i) -> clr
    end for
end showPath

procedure draw
    for i : 1 .. upper (objects)
	objects (i) -> draw
    end for
    for i : 1 .. upper (meteors)
	meteors (i) -> draw
    end for
    if aiming then
	Draw.Line (mx, my, fx, fy, brightred)
	Draw.Line (fx, fy, lx, ly, brightgreen)
	Draw.FillOval (lx, ly, 5, 5, brightgreen)
    end if
    View.Update
end draw

View.Set ("offscreenonly,graphics:max;max")
colourback (black)
colour (brightgreen)

createObject (maxx div 2, maxy div 2, 0, 0, 1000000, yellow, false)
createObject (maxx div 2 + 450, maxy div 2, 0, sqrt (G * 1000000 / 450), 1000, brightblue, true)
createObject (maxx div 2 + 450, maxy div 2 + 15, sqrt (G * 1000 / 15), sqrt (G * 1000000 / 450), 10, grey, true)
createObject (maxx div 2 - 80, maxy div 2, 0, sqrt (G * 1000000 / 80), 100, red, true)
createObject (maxx div 2, maxy div 2 + 200, sqrt (G * 1000000 / 200), 0, 1000, brightred, true)

loop
    cls
    mouseInput
    %showPath               %will cause noticable lag with 3 or more objects. consider turning down the predicted time frame
    gravitation
    collisions
    moveObjects
    draw
    Time.DelaySinceLast (round (1000 / fps))
end loop
