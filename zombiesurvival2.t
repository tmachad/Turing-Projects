View.Set ("offscreenonly,title:Zombie Survival 2")
const sprint := 1.5
const speed := 3
const zomSpd := 2.5
const bulletSpd := 20
const fps := 30

type bullet :
    record
	x, y, xVel, yVel, dmg : real
    end record
var bullets : flexible array 1 .. 0 of bullet

function findAngle (x1, y1, x2, y2 : real) : real
    if x2 < x1 and y2 = y1 then         %going left
	result 0
    elsif x2 = x1 and y2 < y1 then      %going down
	result 90
    elsif x2 > x1 and y2 = y1 then      %going right
	result 180
    elsif x2 = x1 and y2 > y1 then      %going up
	result 270
    elsif x2 <= x1 then
	result arctand ((y2 - y1) / (x2 - x1)) + 180       %left side of x1,y1
    elsif x2 > x1 then
	result arctand ((y2 - y1) / (x2 - x1))             %right side of x1,y1
    else
	result 0
    end if
end findAngle

function angleDiff (angle1, angle2 : real) : real
    var dAngle := angle2 - angle1
    if dAngle > 180 then
	result dAngle - 360
    elsif dAngle < -180 then
	result dAngle + 360
    else
	result dAngle
    end if
end angleDiff

%--------------------------------------player classes--------------------------------------
class plyr
    import var bullets, const bulletSpd, const fps, findAngle
    export var x, var y, var spd, var size, var firingDelay, var ammo, var maxAmmo, ammoUse, var reloadTimer, var reloadSpd, var CoF, mode, shoot, move, draw, reload

    var x, y, spd, dmg, CoF, fireRate, reloadTimer, firingDelay, mode : real
    var size, ammo, maxAmmo, ammoUse, reloadSpd, shots : int
    var reloading, stagger : boolean
    reloading := false

    procedure reload
	if ammo = 0 and reloading = false then
	    reloadTimer := reloadSpd
	    reloading := true
	    %Music.PlayFileReturn ("Pistol Reload.MP3")
	elsif ammo = 0 and reloadTimer <= 0 and reloading then
	    ammo := maxAmmo
	    reloadTimer := 0
	    reloading := false
	end if
	reloadTimer -= 1000 / fps
    end reload

    deferred procedure shoot (mx, my : int)

    procedure move (tmpx, tmpy : real, relative : boolean)
	if relative then
	    x += tmpx
	    y += tmpy
	else
	    x := tmpx
	    y := tmpy
	end if
    end move

    deferred procedure draw

end plyr


class basicPlyr
    inherit plyr

    fireRate := 5               %the number of shotr fired per second. caps out at (fps) shots per second
    firingDelay := round (1000 / fireRate)
    size := 7                       %radius of the player in pixels
    ammoUse := 1                    %the ammount of ammo consumed per shot. used to make weapons exceed max firerate (33.3) or fire bursts
    maxAmmo := ammoUse * 9     %the multiple is the number of shots you will get before needing to reload
    ammo := maxAmmo
    reloadSpd := 1000               %time to reload in milliseconds
    reloadTimer := 0
    dmg := 1                        %damage dealt per shot
    CoF := 5                       %the range of the cone of fire in degrees. bullets will fire within CoF/2 degrees of either side of the cursor
    shots := 1                      %number of shots fired every time the weapon fires
    stagger := false                 %used for weapons that fire bursts or exceed max firerate
    mode := 0                       %determines firing mode; 0 = semi, 1 = auto

    body procedure shoot
	var angle : real
	firingDelay := round (1000 / fireRate)
	for i : 1 .. shots
	    angle := findAngle (x, y, mx, my)
	    new bullets, upper (bullets) + 1
	    if stagger then
		bullets (upper (bullets)).x := x + cosd (angle) * bulletSpd * i / (shots - 1)
		bullets (upper (bullets)).y := y + sind (angle) * bulletSpd * i / (shots - 1)
	    else
		bullets (upper (bullets)).x := x
		bullets (upper (bullets)).y := y
	    end if

	    if Rand.Int (0, 1) = 1 then
		angle += Rand.Real * CoF / 2
	    else
		angle -= Rand.Real * CoF / 2
	    end if
	    bullets (upper (bullets)).xVel := cosd (angle) * bulletSpd
	    bullets (upper (bullets)).yVel := sind (angle) * bulletSpd
	    bullets (upper (bullets)).dmg := dmg

	    %Music.PlayFileReturn ("Fiveseven Shot.WAV")
	end for
    end shoot

    body procedure draw
	Draw.FillOval (round (x), round (y), size, size, black)
    end draw
end basicPlyr

var player : pointer to plyr
new basicPlyr, player

%-------------------------------------zombie classes----------------------------------------
class zombie
    import const zomSpd, var player, const fps, findAngle
    export x, y, xVel, yVel, var hp, size, angle, spd, move, draw, follow, regen

    var x, y, xVel, yVel, hp, maxHp, hpRegen, spd, spdRange, angle : real
    var size : int

    procedure regen
	if hp < maxHp and hp + hpRegen / fps >= maxHp then
	    hp := maxHp
	elsif hp < maxHp then
	    hp += hpRegen / fps
	end if
    end regen

    procedure follow
	angle := findAngle (x, y, player -> x, player -> y)
	xVel := cosd (angle) * spd
	yVel := sind (angle) * spd
    end follow

    procedure move (tmpx, tmpy : real, relative : boolean)
	if relative then
	    x += tmpx
	    y += tmpy
	else
	    x := tmpx
	    y := tmpy
	end if
    end move

    deferred procedure draw
end zombie

class basicZom
    inherit zombie

    maxHp := 2
    hp := maxHp
    hpRegen := 0
    spdRange := 1
    spd := 2.5
    if Rand.Int (0, 1) = 1 then         %gives the zombie a random speed that deviates from the normal speed by a portion of spdRange
	spd += Rand.Real * spdRange
    else
	spd -= Rand.Real * spdRange
    end if
    size := 7

    body procedure draw
	Draw.FillOval (round (x), round (y), size, size, green)
	Draw.Oval (round (x), round (y), size, size, black)
	if hp < maxHp then
	    Draw.Line (round (x) - size, round (y) + size div 3 * 4, round (x) + size, round (y) + size div 3 * 4, brightred)
	    Draw.Line (round (x) - size, round (y) + size div 3 * 4, round (x - size + 2 * size * (hp / maxHp)), round (y) + size div 3 * 4, brightgreen)
	end if
    end draw
end basicZom

var zoms : flexible array 1 .. 0 of pointer to zombie

%--------------------------------turret classes----------------------------------
class turret
    import findAngle, angleDiff, bullets, zoms, Math, const bulletSpd, const fps
    export var x, var y, dmg, var target, var firingDelay, var minAngle, var maxAngle, arc, var angle, CoF, range, shoot, aquireTarget, draw, aim

    var x, y, fireRate, firingDelay, dmg, turnRate, angle, minAngle, maxAngle : real
    var size, CoF, shots, target, range, arc : int
    var stagger : boolean

    procedure aquireTarget
	if upper (zoms) >= lower (zoms) then
	    for i : 1 .. upper (zoms)
		if target = 0 then
		    if Math.Distance (x, y, zoms (i) -> x, zoms (i) -> y) <= range and findAngle (x, y, zoms (i) -> x, zoms (i) -> y) >= minAngle
			    and findAngle (x, y, zoms (i) -> x, zoms (i) -> y) <= maxAngle then
			target := i
		    end if
		else
		    if Math.Distance (x, y, zoms (i) -> x, zoms (i) -> y) <= range and
			    abs (angleDiff (angle, findAngle (x, y, zoms (i) -> x, zoms (i) -> y))) <= abs (angleDiff (angle, findAngle (x, y, zoms (target) -> x, zoms (target) -> y)))
			    and i not= target and findAngle (x, y, zoms (i) -> x, zoms (i) -> y) >= minAngle and findAngle (x, y, zoms (i) -> x, zoms (i) -> y) <= maxAngle then
			target := i
		    end if
		end if
	    end for
	else
	    target := 0
	end if
    end aquireTarget

    procedure aim
	var dAngle := angleDiff (angle, findAngle (x, y, zoms (target) -> x, zoms (target) -> y))

	if angleDiff (angle + dAngle, minAngle) < 0 and angleDiff (angle + dAngle, maxAngle) > 0 then
	    if dAngle < 0 and dAngle < -turnRate / fps then
		angle -= turnRate / fps
	    elsif dAngle < 0 then
		angle += dAngle
	    end if
	    if dAngle > 0 and dAngle > turnRate / fps then
		angle += turnRate / fps
	    elsif dAngle > 0 then
		angle += dAngle
	    end if
	end if
	if angle >= 360 then
	    angle -= 360
	elsif angle < 0 then
	    angle += 360
	end if
    end aim

    deferred procedure shoot

    deferred procedure draw

end turret

class basicTurret
    inherit turret

    turnRate := 180         %the number of degrees that the turret can turn in 1 second
    target := 0
    size := 7               %the radius of the turret in pixels
    range := 250            %the range of the turret in pixels
    CoF := 10               %the cone of fire of the turret. The turret's shots will go within CoF/2 degrees of its facing
    arc := 60               %the turning arc of the turret. It can turn arc/2 degrees to either side of its initial facing
    shots := 2
    fireRate := 10
    firingDelay := 1000 / fireRate
    dmg := .5
    stagger := true

    body procedure shoot
	firingDelay := round (1000 / fireRate)
	for i : 1 .. shots
	    new bullets, upper (bullets) + 1
	    bullets (upper (bullets)).x := x
	    bullets (upper (bullets)).y := y

	    var tmpAngle := angle

	    if stagger then
		bullets (upper (bullets)).x := x + cosd (tmpAngle) * bulletSpd * i / (shots - 1)
		bullets (upper (bullets)).y := y + sind (tmpAngle) * bulletSpd * i / (shots - 1)
	    else
		bullets (upper (bullets)).x := x
		bullets (upper (bullets)).y := y
	    end if

	    if Rand.Int (0, 1) = 1 then
		tmpAngle += Rand.Real * CoF / 2
	    else
		tmpAngle -= Rand.Real * CoF / 2
	    end if
	    bullets (upper (bullets)).xVel := cosd (tmpAngle) * bulletSpd
	    bullets (upper (bullets)).yVel := sind (tmpAngle) * bulletSpd
	    bullets (upper (bullets)).dmg := dmg
	end for
    end shoot

    body procedure draw
	Draw.FillOval (round (x), round (y), size, size, gray)
	Draw.ThickLine (round (x), round (y), round (x + cosd (angle) * size * 1.5), round (y + sind (angle) * size * 1.5), 3, gray)
	Draw.Arc (round (x), round (y), range, range, round (minAngle), round (maxAngle), brightgreen)
	%show arc
	if minAngle not= maxAngle and minAngle < maxAngle then
	    Draw.Line (round (x), round (y), round (x + cosd (maxAngle) * range), round (y + sind (maxAngle) * range), brightgreen)
	    Draw.Line (round (x), round (y), round (x + cosd (minAngle) * range), round (y + sind (minAngle) * range), brightgreen)
	end if
	%show CoF
	Draw.Line (round (x), round (y), round (x + cosd (angle + CoF / 2) * range), round (y + sind (angle + CoF / 2) * range), brightgreen)
	Draw.Line (round (x), round (y), round (x + cosd (angle - CoF / 2) * range), round (y + sind (angle - CoF / 2) * range), brightgreen)
    end draw
end basicTurret

var turrets : flexible array 1 .. 0 of pointer to turret


var score : int
%------------------shooting stuff---------------------
procedure killBullet (counter : int)
    for i : counter .. upper (bullets) - 1
	bullets (i) := bullets (i + 1)
    end for
    new bullets, upper (bullets) - 1
end killBullet

procedure bulletCleanup
    var counter : int := 1
    if upper (bullets) >= lower (bullets) then
	loop
	    if bullets (counter).x > maxx or bullets (counter).x < 0
		    or bullets (counter).y > maxy or bullets (counter).y < 0 then
		killBullet (counter)
	    else
		counter += 1
	    end if
	    exit when counter >= upper (bullets)
	end loop
    end if
end bulletCleanup

procedure moveBullets
    for i : lower (bullets) .. upper (bullets)
	bullets (i).x += bullets (i).xVel
	bullets (i).y += bullets (i).yVel
    end for
end moveBullets

var kills, shots : int := 0
var blockClick : boolean := false
procedure mouse
    var mx, my, mbtn : int
    Mouse.Where (mx, my, mbtn)
    if player -> mode = 0 then
	if mbtn = 1 and blockClick = false and player -> firingDelay <= 0 and player -> ammo >= player -> ammoUse then
	    player -> shoot (mx, my)
	    shots += 1
	    player -> ammo -= player -> ammoUse
	    blockClick := true
	else
	    player -> firingDelay -= 1000 / fps
	end if
	if mbtn = 0 then
	    blockClick := false
	end if
    elsif player -> mode = 1 then
	if mbtn = 1 and player -> firingDelay <= 0 and player -> ammo >= player -> ammoUse then
	    player -> shoot (mx, my)
	    shots += 1
	    player -> ammo -= player -> ammoUse
	else
	    player -> firingDelay -= 1000 / fps
	end if
    end if
    if player -> ammo < player -> ammoUse then
	player -> reload
    end if
end mouse

%----------------------------turret stuff---------------------------
procedure createTurret (x, y, angle : real)
    new turrets, upper (turrets) + 1
    new basicTurret, turrets (upper (turrets))
    turrets (upper (turrets)) -> x := x
    turrets (upper (turrets)) -> y := y
    turrets (upper (turrets)) -> angle := angle
    turrets (upper (turrets)) -> minAngle := angle - turrets (upper (turrets)) -> arc / 2
    % if turrets (upper (turrets)) -> minAngle < 0 then
    %     turrets (upper (turrets)) -> minAngle += 360
    % end if
    turrets (upper (turrets)) -> maxAngle := angle + turrets (upper (turrets)) -> arc / 2
    % if turrets (upper (turrets)) -> maxAngle >= 360 then
    %     turrets (upper (turrets)) -> maxAngle -= 360
    % end if
end createTurret


procedure manageTurrets
    for i : 1 .. upper (turrets)
	if turrets (i) -> target = 0 or turrets (i) -> target > upper (zoms)
		or Math.Distance (turrets (i) -> x, turrets (i) -> y, zoms (turrets (i) -> target) -> x, zoms (turrets (i) -> target) -> y) > turrets (i) -> range then
	    %select a new target if the turret doesn't have one or the current target doesn't exist
	    turrets (i) -> aquireTarget
	end if

	if turrets (i) -> target > 0 then
	    turrets (i) -> aim
	    if abs (angleDiff (turrets (i) -> angle, findAngle (turrets (i) -> x, turrets (i) -> y, zoms (turrets (i) -> target) -> x, zoms (turrets (i) -> target) -> y))) <= turrets (i) -> CoF /
		    2
		    then
		if turrets (i) -> firingDelay <= 0 and Math.Distance (turrets (i) -> x, turrets (i) -> y,
			zoms (turrets (i) -> target) -> x, zoms (turrets (i) -> target) -> y) <= turrets (i) -> range then
		    turrets (i) -> shoot
		end if
	    end if
	end if

	if turrets (i) -> firingDelay > 0 then
	    turrets (i) -> firingDelay -= 1000 / fps
	end if
    end for
end manageTurrets

%----------------------zombie stuff-----------------------------

function zomCollide (zom : int, dX, dY, overlap : real) : boolean
    for i : 1 .. upper (zoms)
	if Math.Distance (zoms (zom) -> x + dX, zoms (zom) -> y + dY, zoms (i) -> x, zoms (i) -> y) <= zoms (zom) -> size + zoms (i) -> size - overlap
		and i not= zom then
	    result true
	end if
    end for
    result false
end zomCollide

procedure goAround (zom : int)
    if Rand.Int (0, 1) = 1 then
	if zomCollide (zom, cosd (zoms (zom) -> angle + 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle + 90) * zoms (zom) -> spd, 1) = false then
	    zoms (zom) -> move (cosd (zoms (zom) -> angle + 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle + 90) * zoms (zom) -> spd, true)
	elsif zomCollide (zom, cosd (zoms (zom) -> angle - 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle - 90) * zoms (zom) -> spd, 1) = false then
	    zoms (zom) -> move (cosd (zoms (zom) -> angle - 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle - 90) * zoms (zom) -> spd, true)
	end if
    else
	if zomCollide (zom, cosd (zoms (zom) -> angle - 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle - 90) * zoms (zom) -> spd, 1) = false then
	    zoms (zom) -> move (cosd (zoms (zom) -> angle - 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle - 90) * zoms (zom) -> spd, true)
	elsif zomCollide (zom, cosd (zoms (zom) -> angle + 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle + 90) * zoms (zom) -> spd, 1) = false then
	    zoms (zom) -> move (cosd (zoms (zom) -> angle + 90) * zoms (zom) -> spd, sind (zoms (zom) -> angle + 90) * zoms (zom) -> spd, true)
	end if
    end if
end goAround

procedure manageZoms
    for i : 1 .. upper (zoms)
	zoms (i) -> follow
	if zomCollide (i, zoms (i) -> xVel, zoms (i) -> yVel, 1) = false then
	    zoms (i) -> move (zoms (i) -> xVel, zoms (i) -> yVel, true)
	else
	    goAround (i)
	end if
	zoms (i) -> regen
    end for
end manageZoms

procedure killZom (counter : int)
    for i : counter .. upper (zoms) - 1
	zoms (i) := zoms (i + 1)
    end for
    new zoms, upper (zoms) - 1
end killZom

procedure createZombie
    new zoms, upper (zoms) + 1
    new basicZom, zoms (upper (zoms))
    case Rand.Int (1, 4) of
	label 1 :
	    loop
		zoms (upper (zoms)) -> move (maxx + Rand.Int (1, 10) + zoms (upper (zoms)) -> size, Rand.Int (1, maxy), false)
		exit when zomCollide (upper (zoms), 0, 0, 0) = false
	    end loop
	label 2 :
	    loop
		zoms (upper (zoms)) -> move (Rand.Int (1, maxx), 0 - Rand.Int (1, 10) - zoms (upper (zoms)) -> size div 2, false)
		exit when zomCollide (upper (zoms), 0, 0, 0) = false
	    end loop
	label 3 :
	    loop
		zoms (upper (zoms)) -> move (0 - Rand.Int (1, 10) - zoms (upper (zoms)) -> size div 2, Rand.Int (1, maxy), false)
		exit when zomCollide (upper (zoms), 0, 0, 0) = false
	    end loop
	label 4 :
	    loop
		zoms (upper (zoms)) -> move (Rand.Int (1, maxx), maxy + Rand.Int (1, 10) + zoms (upper (zoms)) -> size div 2, false)
		exit when zomCollide (upper (zoms), 0, 0, 0) = false
	    end loop
    end case
end createZombie

var spawnDelay, spawnTimer : real
var spawnsLeft, roundNum : int := 0
var groupSpawn : boolean

procedure spawnZombies
    if spawnDelay <= 0 then
	for i : 1 .. ceil (1 / spawnTimer / fps)
	    if spawnsLeft > 0 then
		createZombie
		spawnsLeft -= 1
	    end if
	end for
    else
	spawnDelay -= 1000 / fps
    end if
end spawnZombies

%------------------rounds-----------------------
var roundX, roundY, rFontSize : int
procedure startRound
    if upper (zoms) = 0 and spawnsLeft = 0 then
	roundNum += 1
	score += (roundNum - 1) * 100
	roundX := maxx div 4
	roundY := maxy div 9 * 4
	rFontSize := 60
	spawnDelay := 2000
	spawnTimer := 5000
	spawnsLeft := 3 + 2 * roundNum
	groupSpawn := false
    end if
end startRound

rFontSize := 10
roundX := 1
roundY := maxy - 10
procedure roundSize
    if rFontSize > 10 then
	rFontSize -= 1
    end if
    if rFontSize < 10 then
	rFontSize := 10
    end if
    if roundX > 1 then
	roundX -= maxx div 200
    end if
    if roundX < 1 then
	roundX := 1
    end if
    if roundY < maxy - 10 then
	roundY += maxy div 80
    end if
    if roundY > maxy - 10 then
	roundY := maxy - 10
    end if
end roundSize

procedure manageRounds
    startRound
    roundSize
    spawnZombies
end manageRounds

%------------------high scores------------------
type scores :
    record
	name : string (5)
	score : int
    end record
var highScores : array 1 .. 10 of scores
var currentHS : scores
currentHS.name := ""

const fileName := "Zom2HS.bin"
var fileNo : int
procedure createFile
    open : fileNo, fileName, write
    for i : 1 .. 10
	highScores (i).name := "Name"
	highScores (i).score := 0
	write : fileNo, highScores (i)
    end for
    close : fileNo
end createFile

procedure loadHS
    if File.Exists (fileName) then
	open : fileNo, fileName, read
	for i : 1 .. 10
	    read : fileNo, highScores (i)
	end for
	close : fileNo
    else
	createFile
	loadHS
    end if
end loadHS

procedure saveHS
    open : fileNo, fileName, write
    for i : 1 .. 10
	write : fileNo, highScores (i)
    end for
    close : fileNo
end saveHS

procedure sortScores
    for i : 1 .. 10
	if i = 1 then
	    if currentHS.score >= highScores (i).score then
		for decreasing j : 10 .. 2
		    highScores (j).score := highScores (j - 1).score
		    highScores (j).name := highScores (j - 1).name
		end for
		highScores (i).score := currentHS.score
		highScores (i).name := currentHS.name
	    end if
	else
	    if currentHS.score >= highScores (i).score and currentHS.score < highScores (i - 1).score then
		for decreasing j : 10 .. i
		    highScores (j).score := highScores (j - 1).score
		    highScores (j).name := highScores (j - 1).name
		end for
		highScores (i).score := currentHS.score
		highScores (i).name := currentHS.name
	    end if
	end if
    end for
end sortScores

procedure getName
    var test : string
    loop
	locate (20, maxcol div 2 - 6)
	put ""
	locate (20, maxcol div 2 - 6)
	put "Name: " ..
	View.Update
	get test
	if length (test) <= 5 then
	    currentHS.name := test
	    currentHS.score := score
	    exit
	end if
    end loop
end getName

procedure displayHS
    loadHS
    locate (7, maxcol div 2 - 6)
    put "High Scores"
    for i : 1 .. 10
	if highScores (i).name = currentHS.name and highScores (i).score = currentHS.score then
	    locate (7 + i, maxcol div 2 - 9)
	    put ">"
	end if
	locate (7 + i, maxcol div 2 - 7)
	put highScores (i).name
	locate (7 + i, maxcol div 2 + 6 - length (intstr (highScores (i).score)))
	put highScores (i).score
	if highScores (i).name = currentHS.name and highScores (i).score = currentHS.score then
	    locate (7 + i, maxcol div 2 + 7)
	    put "<"
	end if
    end for
    locate (19, maxcol div 2 - (4 + length (intstr (score)) div 2))
    put "Score: ", score
end displayHS


%------------------losing-----------------------
procedure playAgain
    View.Set ("offscreenonly")
    player -> x := maxx / 2
    player -> y := maxy / 2
    score := 0
    roundNum := 0
    kills := 0
    shots := 0
    new zoms, 0
    new bullets, 0
    currentHS.name := ""
    currentHS.score := 0
end playAgain

procedure aimInfo
    var accuracy : int
    if shots > 0 and kills > 0 then
	accuracy := round (kills / shots * 100)
	locate (5, maxcol div 2 - (7 - length (intstr (accuracy)) div 2))
	put "Accuracy: ", accuracy, "%    " ..
	if accuracy <= 10 then
	    put "FAILURE AT LIFE!"
	elsif accuracy > 10 and accuracy <= 20 then
	    put "OUCH!"
	elsif accuracy > 20 and accuracy <= 30 then
	    put "Sub-par"
	elsif accuracy > 30 and accuracy <= 40 then
	    put "Not great"
	elsif accuracy > 40 and accuracy <= 50 then
	    put "Meh"
	elsif accuracy > 50 and accuracy <= 60 then
	    put "At least you didn't fail!"
	elsif accuracy > 60 and accuracy <= 70 then
	    put "OK"
	elsif accuracy > 70 and accuracy <= 80 then
	    put "Good!"
	elsif accuracy > 80 and accuracy <= 90 then
	    put "Awesome!"
	elsif accuracy > 90 and accuracy <= 100 then
	    put "GODLIKE!"
	elsif accuracy > 100 then
	    put "BEYOND GODLIKE!"
	end if
    else
	locate (6, maxcol div 2 - 5)
	put "PACIFIST!"
    end if
end aimInfo

var chars : array char of boolean
var exitGame := false
procedure gameOver
    View.Set ("nooffscreenonly")
    cls
    locate (1, maxcol div 2 - 5)
    put "GAME OVER"
    locate (2, maxcol div 2 - 7)
    put "RIP - Dot Dude"
    locate (3, maxcol div 2 - (11 + length (intstr (kills)) div 2))
    put "Zombies Exterminated: ", kills
    locate (4, maxcol div 2 - (7 + length (intstr (shots)) div 2))
    put "Shots Fired: ", shots
    aimInfo
    put ""
    displayHS
    getName
    sortScores
    saveHS
    displayHS
    locate (21, maxcol div 2 - 14)
    %put "Press <Enter> To Play Again"
    locate (22, maxcol div 2 - 10)
    put "Press <Esc> To Quit"
    delay (500)
    Input.Flush
    loop
	Input.KeyDown (chars)
	% if chars (KEY_ENTER) then
	%     playAgain
	%     exit
	elsif chars (KEY_ESC) then
	    exitGame := true
	    exit
	end if
    end loop
end gameOver

%---------------------zombie, shooting, and player interaction---------------------
procedure collisions
    %----------bullet & zombie collisions-------------
    if upper (zoms) >= lower (zoms) and upper (bullets) >= lower (bullets) then
	var i, j : int
	var killed : boolean
	i := 1
	loop
	    j := 1
	    killed := false
	    loop
		if Math.DistancePointLine (zoms (i) -> x, zoms (i) -> y, bullets (j).x, bullets (j).y, bullets (j).x - bullets (j).xVel, bullets (j).y - bullets (j).yVel) <= zoms (i) -> size then
		    zoms (i) -> hp -= bullets (j).dmg
		    killBullet (j)
		    if zoms (i) -> hp <= 0 then
			kills += 1
			killZom (i)
			killed := true
			score += 10
			for k : 1 .. upper (turrets)
			    if turrets (k) -> target = i then
				turrets (k) -> target := 0
			    elsif turrets (k) -> target > i then
				turrets (k) -> target -= 1
			    end if
			end for
		    end if
		else
		    j += 1
		end if
		exit when j > upper (bullets) or killed
	    end loop
	    if killed not= true then
		i += 1
	    end if
	    exit when i > upper (zoms) or upper (bullets) = 0
	end loop
    end if
    %-----------player & zombie collisions------------
    if upper (zoms) >= lower (zoms) then
	var k : int := 0
	loop
	    k += 1
	    if Math.Distance (zoms (k) -> x, zoms (k) -> y, player -> x, player -> y) <= zoms (k) -> size + player -> size then
		gameOver
	    end if
	    exit when k >= upper (zoms) or exitGame
	end loop
    end if
end collisions

%-----------------------player stuff-----------------------
const maxStamina : real := 3000
const staminaRegen := 1000 / fps
const staminaUse := 1000 / fps
var stamina := maxStamina

procedure keyPresses
    Input.KeyDown (chars)
    if chars ('w') and player -> y < maxy then
	if chars (KEY_SHIFT) and stamina >= 30 then
	    player -> move (0, speed * sprint, true)
	else
	    player -> move (0, speed, true)
	end if
    end if
    if chars ('a') and player -> x > 0 then
	if chars (KEY_SHIFT) and stamina >= 30 then
	    player -> move (-speed * sprint, 0, true)
	else
	    player -> move (-speed, 0, true)
	end if
    end if
    if chars ('s') and player -> y > 0 then
	if chars (KEY_SHIFT) and stamina >= 30 then
	    player -> move (0, -speed * sprint, true)
	else
	    player -> move (0, -speed, true)
	end if
    end if
    if chars ('d') and player -> x < maxx then
	if chars (KEY_SHIFT) and stamina >= 30 then
	    player -> move (speed * sprint, 0, true)
	else
	    player -> move (speed, 0, true)
	end if
    end if
    if chars (KEY_SHIFT) and stamina >= staminaUse then
	stamina -= staminaUse
    elsif stamina not= maxStamina and chars (KEY_SHIFT) = false then
	stamina += staminaRegen
    end if
    if chars ('r') and player -> ammo < player -> maxAmmo then
	player -> ammo := 0
	player -> reload
    end if
end keyPresses

%------------------------drawing-----------------------
procedure drawCrosshair (mx, my : int)
    var style := 1
    if style = 1 then
	var c, r, a : real
	r := Math.Distance (mx, my, player -> x, player -> y)
	c := 2 * 3.14 * r
	a := ((player -> CoF / 2) * c) / 360

	Draw.Oval (mx, my, round (a), round (a), brightgreen)
    elsif style = 2 then
	Draw.Arc (round (player -> x), round (player -> y), round (Math.Distance (player -> x, player -> y, mx, my)), round (Math.Distance (player -> x, player -> y, mx, my)),
	    round (findAngle (player -> x, player -> y, mx, my) - player -> CoF / 2), round (findAngle (player -> x, player -> y, mx, my) + player -> CoF / 2), brightgreen)
    else

    end if
end drawCrosshair

procedure draw
    var mx, my, mbtn : int
    Mouse.Where (mx, my, mbtn)
    var font := Font.New ("arial:10")
    var rFont := Font.New ("arial:" + intstr (rFontSize))
    cls
    %-----------draw turrets-------------
    if upper (turrets) >= lower (turrets) then
	for i : 1 .. upper (turrets)
	    turrets (i) -> draw
	    if turrets (i) -> target > 0 then
		Draw.Line (round (turrets (i) -> x), round (turrets (i) -> y), round (zoms (turrets (i) -> target) -> x), round (zoms (turrets (i) -> target) -> y), brightred)
	    end if
	end for
    end if
    %-----------draw player-------------
    player -> draw
    %------------draw bullets-----------
    if upper (bullets) >= lower (bullets) then
	for i : lower (bullets) .. upper (bullets)
	    Draw.Line (round (bullets (i).x), round (bullets (i).y), round (bullets (i).x - bullets (i).xVel), round (bullets (i).y - bullets (i).yVel), black)
	end for
    end if
    %----------draw zombies------------
    if upper (zoms) >= lower (zoms) then
	for i : lower (zoms) .. upper (zoms)
	    zoms (i) -> draw
	    %Font.Draw (intstr (i), round (zoms (i) -> x - Font.Width (intstr (i), font) / 2), round (zoms (i) -> y - 5), font, brightred)
	end for
    end if
    %-----------draw HUD---------------
    Draw.FillBox (0, 0, 0 + round (stamina / maxStamina * 100) * 2, 10, brightgreen)
    Draw.Box (0, 0, 200, 10, black)
    if player -> ammo = 0 and player -> reloadSpd > 0 then
	Draw.Arc (mx, my, 10, 10, 90, 90 + round (360 * player -> reloadTimer / player -> reloadSpd), black)
    end if
    drawCrosshair (mx, my)
    Font.Draw ("Round " + intstr (roundNum), roundX, roundY, rFont, black)
    Font.Draw (intstr (upper (zoms) + spawnsLeft) + " Zombies Remaining", 1, maxy - 21, font, black)
    Font.Draw ("Score " + intstr (score), 1, maxy - 32, font, black)
    Font.Draw (intstr (player -> ammo) + "/" + intstr (player -> maxAmmo), maxx - Font.Width (intstr (player -> ammo) + "/" + intstr (player -> maxAmmo), font), 10, font, black)
    Font.Free (font)
    Font.Free (rFont)
    View.Update
end draw

%-------------initalization-----------------

player -> move (maxx div 2, maxy div 2, false)
score := 0
roundNum := 0
createTurret (100, 200, 0)
%------------------main-------------------
loop
    manageRounds
    keyPresses
    manageZoms
    manageTurrets
    mouse
    moveBullets
    collisions
    exit when exitGame
    bulletCleanup
    draw
    Time.DelaySinceLast (round (1000 / fps))
end loop
cls











