debug = false
screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()

world = nil

objects = {}

player = {
    size = 100,
    ratio = 2.2,
    touchid = nil,
    state = "alive",
    score = 0,
    canShoot = true,
    canShootTimerMax = 0.2,
    canShootTimer = 0.2,
    isShooting = false,
    bulletSpeed = 4000
}

images = {
    player = love.graphics.newImage('assets/ship.png'),
    target = love.graphics.newImage('assets/Crosshair 1.png'),
    enemy = love.graphics.newImage('assets/Aircraft_01.png')
}

-- Bullets
bulletImg = love.graphics.newImage('assets/bullet_2_blue.png')
bullets = {} -- array of current bullets being drawn and updated

enemies = {}
enemyTimerMax = 4
enemyTimer = enemyTimerMax

function love.load(arg)
    love.mouse.setVisible(false)
    setScale()

    world = love.physics.newWorld(0, 0)

    createPlayer()
end

function love.update(dt)
    world:update(dt)

    player.body:setAngle(calcAngle(player, target))

    -- Time out how far apart our shots can be.
    player.canShootTimer = player.canShootTimer - (1 * dt)
    if player.canShootTimer < 0 then player.canShoot = true end

    if player.isShooting and player.canShoot then
        createBullet()
        player.canShoot = false
        player.canShootTimer = player.canShootTimerMax
    end

    -- cleanup bullets
    for i, bullet in ipairs(bullets) do
        local x = bullet.body:getX()
        local y = bullet.body:getY()
        if y < 0 or y > screenHeight or x < 0 or x > screenWidth then
            table.remove(bullets, i)
            table.remove(objects, tablefind(objects, bullet))
        end
    end

    enemyTimer = enemyTimer - dt
    if enemyTimer < 0 then
        createEnemy()
        enemyTimer = enemyTimerMax
    end

    -- cleanup enemies
    for i, enemy in ipairs(enemies) do
        local x = enemy.body:getX()
        local y = enemy.body:getY()
        if y < 0 or y > screenHeight or x < 0 or x > screenWidth then
            table.remove(enemies, i)
            table.remove(objects, tablefind(objects, enemy))
        end

        enemy.body:setAngle(calcAngle(enemy, player))
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'd' and not isrepeat then debug = not debug end

    if love.keyboard.isDown('escape') then love.event.push('quit') end
end

function love.draw()
    if debug then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("DT: " .. tostring(love.timer.getDelta()), 10, 10)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 20)
        love.graphics.print("Screen " .. tostring(love.graphics.getWidth()) ..
                                "x" .. tostring(love.graphics.getHeight()) ..
                                " scale " .. tostring(sx) .. "x" .. tostring(sy),
                            10, 30)
        love.graphics.print("Shooting: " .. tostring(player.isShooting) ..
                                "  Bullets: " .. tostring(#bullets), 10, 40)
        love.graphics.print("Angle: " .. tostring(player.body:getAngle()), 10,
                            50)
        love.graphics.print("Enemies: " .. tostring(#enemies), 10, 60)

        -- bullet spawn
        love.graphics.circle("fill", player.body:getX() +
                                 (math.sin(player.body:getAngle()) * 50 * sx),
                             player.body:getY() +
                                 (math.cos(player.body:getAngle()) * -50 * sy),
                             10 * sx)
        drawPhysicsShapes()
    end

    love.graphics.setColor(1, 1, 1)
    for i, o in ipairs(objects) do
        if not o.hidden then
            love.graphics.draw(o.img, o.body:getX(), o.body:getY(),
                               o.body:getAngle(), 1, 1, o.img:getWidth() / 2,
                               o.img:getHeight() / 2)
        end
    end

    -- for i, bullet in ipairs(bullets) do
    --     love.graphics.draw(bullet.img, bullet.x, bullet.y)
    -- end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if (player.touchid == nil) then
        player.touchid = id
        player.joint:setTarget(x, y)
    else
        target.touchid = id
        target.joint:setTarget(x, y)
        player.isShooting = true
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if (player.touchid == id) then
        player.joint:setTarget(x, y)
    elseif (target.touchid == id) then
        target.joint:setTarget(x, y)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if (player.touchid == id) then
        player.touchid = nil
    elseif (target.touchid == id) then
        target.touchid = nil
        player.isShooting = false
    end
end

function getCircle(size, color)
    local circle = love.graphics.newCanvas(size, size)
    love.graphics.setCanvas(circle)
    love.graphics.setColor(color.r, color.g, color.b, 1)

    love.graphics.circle("fill", size / 2, size / 2, size / 2)

    love.graphics.setCanvas()
    return circle
end

function getRectangle(width, height, color)
    local rect = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(rect)
    love.graphics.setColor(color.r, color.g, color.b)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setCanvas()
    return rect
end

function setScale()
    local width, height = love.graphics.getDimensions()
    sx = width / 1920
    sy = height / 1080
    player.size = player.size * sx
end

function createPlayer()
    player.img = scale(images.player, player.ratio * sx, player.ratio * sy)
    player.ratioX = player.ratio * sx
    player.ratioY = player.ratio * sy

    player.body = love.physics.newBody(world, player.size * 1.5,
                                       screenHeight / 2, "dynamic")
    player.shape = love.physics.newPolygonShape(0, -15 * player.ratioY,
                                                23 * player.ratioX,
                                                15 * player.ratioY,
                                                -23 * player.ratioX,
                                                15 * player.ratioY)
    player.fixture = love.physics.newFixture(player.body, player.shape)
    player.joint = love.physics.newMouseJoint(player.body, player.size * 1.5,
                                              screenHeight / 2)

    table.insert(objects, player)

    target = {
        img = scale(images.target, .1 * sx, .1 * sy),
        touchid = nil,
        hidden = false
    }
    target.body = love.physics.newBody(world, player.size * 10,
                                       screenHeight / 2, "dynamic")
    -- target.shape = love.physics.newCircleShape(player.size / 2)
    -- target.fixture = love.physics.newFixture(target.body, target.shape)
    target.joint = love.physics.newMouseJoint(target.body, player.size * 10,
                                              screenHeight / 2)

    table.insert(objects, target)
end

function scale(img, ratioX, ratioY)
    local c = love.graphics.newCanvas(img:getWidth() * ratioX,
                                      img:getHeight() * ratioY)
    love.graphics.setCanvas(c)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img, 0, 0, 0, ratioX, ratioY)
    love.graphics.setCanvas()

    return c
end

function calcAngle(o1, o2)
    return -math.atan2(o1.body:getX() - o2.body:getX(),
                       o1.body:getY() - o2.body:getY())
end

-- https://love2d.org/wiki/Tutorial:PhysicsDrawing
function drawPhysicsShapes()
    for _, body in pairs(world:getBodies()) do
        for _, fixture in pairs(body:getFixtures()) do
            local shape = fixture:getShape()

            if shape:typeOf("CircleShape") then
                local cx, cy = body:getWorldPoints(shape:getPoint())
                love.graphics.circle("fill", cx, cy, shape:getRadius())
            elseif shape:typeOf("PolygonShape") then
                love.graphics.polygon("fill",
                                      body:getWorldPoints(shape:getPoints()))
            else
                love.graphics.line(body:getWorldPoints(shape:getPoints()))
            end
        end
    end
end

function createBullet()
    local bullet = {
        x = player.body:getX() + (player.img:getWidth() / 2),
        y = player.body:getY(),
        img = scale(bulletImg, sx, sy)
    }

    bullet.body = love.physics.newBody(world, player.body:getX() +
                                           (math.sin(player.body:getAngle()) *
                                               50 * sx), player.body:getY() +
                                           (math.cos(player.body:getAngle()) *
                                               -50 * sy), "kinematic")

    bullet.shape = love.physics.newRectangleShape(bullet.img:getWidth(),
                                                  bullet.img:getHeight())
    bullet.fixture = love.physics.newFixture(bullet.body, bullet.shape)

    bullet.body:setBullet(true)
    bullet.body:setAngle(player.body:getAngle())
    bullet.body:setLinearVelocity(math.sin(player.body:getAngle()) *
                                      player.bulletSpeed, math.cos(
                                      player.body:getAngle()) *
                                      player.bulletSpeed * -1)

    table.insert(bullets, bullet)
    table.insert(objects, bullet)
end

function tablefind(tab, el)
    for index, value in pairs(tab) do if value == el then return index end end
end

function createEnemy()
    local enemy = {
        size = 100,
        ratio = love.math.random(.5, 5),
        touchid = nil,
        state = "alive",
        canShoot = true,
        canShootTimerMax = 0.2,
        canShootTimer = 0.2,
        isShooting = false,
        bulletSpeed = 1000,
        speed = love.math.random(50, 500)
    }

    enemy.img = scale(images.enemy, enemy.ratio * sx, enemy.ratio * sy)
    enemy.ratioX = enemy.ratio * sx
    enemy.ratioY = enemy.ratio * sy

    local x = love.math.random(love.graphics.getWidth())
    local y = love.math.random(love.graphics.getHeight())

    enemy.body = love.physics.newBody(world, x, y, "dynamic")
    enemy.shape = love.physics.newCircleShape(50  * enemy.ratio)
    enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape)

    enemy.body:setAngle(calcAngle(enemy, player))
    enemy.body:setLinearVelocity(math.sin(enemy.body:getAngle()) *
                                enemy.speed, math.cos(
                                enemy.body:getAngle()) *
                                enemy.speed * -1)

    table.insert(objects, enemy)
    table.insert(enemies, enemy)
end
