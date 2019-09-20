debug = false
screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()

shipSize = 100

world = nil

objects = {}

function love.load(arg)
    setScale()

    world = love.physics.newWorld(0, 0)

    createShip()
end

function love.update(dt)
    world:update(dt)

    ship.body:setAngle(calcAngle())
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
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if (ship.touchid == nil) then
        ship.touchid = id
        ship.joint:setTarget(x, y)
    else
        target.touchid = id
        target.joint:setTarget(x, y)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if (ship.touchid == id) then
        ship.joint:setTarget(x, y)
    elseif (target.touchid == id) then
        target.joint:setTarget(x, y)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if (ship.touchid == id) then
        ship.touchid = nil
    elseif (target.touchid == id) then
        target.touchid = nil
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
    shipSize = shipSize * sx
end

function createShip()
    ship = {
        img = scale(love.graphics.newImage('assets/ship.png'), 2.2 * sx,
                    2.2 * sy),
        touchid = nil,
        ratioX = 2.2 * sx,
        ratioY = 2.2 * sy
    }
    ship.body = love.physics.newBody(world, shipSize * 1.5, screenHeight / 2,
                                     "dynamic")
    ship.shape = love.physics.newPolygonShape(0, -15 * ship.ratioY,
                                              23 * ship.ratioX, 15 * ship.ratioY,
                                              -23 * ship.ratioX, 15 * ship.ratioY)
    ship.fixture = love.physics.newFixture(ship.body, ship.shape)
    ship.joint = love.physics.newMouseJoint(ship.body, shipSize * 1.5,
                                            screenHeight / 2)

    table.insert(objects, ship)

    target = { -- TODO Change to crosshair
        img = scale(love.graphics.newImage('assets/Crosshair 1.png'), .1 * sx,
                    .1 * sy),
        touchid = nil,
        hidden = false
    }
    target.body = love.physics.newBody(world, shipSize * 10, screenHeight / 2,
                                       "dynamic")
    -- target.shape = love.physics.newCircleShape(shipSize / 2)
    -- target.fixture = love.physics.newFixture(target.body, target.shape)
    target.joint = love.physics.newMouseJoint(target.body, shipSize * 10,
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

function calcAngle()
    return -math.atan2(ship.body:getX() - target.body:getX(),
                       ship.body:getY() - target.body:getY())
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
