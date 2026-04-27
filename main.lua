gameOver = false
gamePaused = false
debug = false
gameState = "menu"

gameObjects = {}
level = 1
points = 100
levelSpeed = 1
shouldCreate = 5
pointsAndObjects = 0
destroyingTimer = 0
levelTimer = 0
levelCountdown = 0

FISH_POINTS = -50
TRASH_POINTS = 10

buttonWidth = 200
buttonHeight = 60

-- Function to detect collision between objects
function collide(x, y, object)
  return object.x <= x and x <= object.x + object.width and object.y <= y and y <= object.y + object.height
end

-- Function to create a sprite object
function makeSprite(path, x, y, scale, speed)
  local object = {}
  object.image = love.graphics.newImage("graphics/" .. path .. ".png")
  object.x = x
  object.y = y
  object.speed = speed
  if scale == nil then
    scale = 1
  end
  object.scale = scale
  object.width = object.image:getWidth() * scale
  object.height = object.image:getHeight() * scale
  object.tags = {}
  object.opacity = 1
  object.removing = false
  return object
end

-- Function to draw a button with text
function drawButton(text, x, y, width, height)
  love.graphics.setColor(0.2, 0.2, 0.8, 1) -- Blue button
  love.graphics.rectangle("fill", x, y, width, height, 10)
  love.graphics.setColor(1, 1, 1, 1) -- White text
  love.graphics.setFont(buttonFont)
  local textX = x + (width - buttonFont:getWidth(text)) / 2
  local textY = y + (height - buttonFont:getHeight(text)) / 2
  love.graphics.print(text, textX, textY)
end

-- Function to draw the start menu
function drawMenu()
  love.graphics.setFont(font)
  local titleText = "Trash Collector Game"
  love.graphics.print(titleText, love.graphics.getWidth() / 2 - font:getWidth(titleText) / 2, 150)

  -- Draw start button
  local startX = love.graphics.getWidth() / 2 - buttonWidth / 2
  local startY = 300
  drawButton("Start Game", startX, startY, buttonWidth, buttonHeight)
end

-- Function to draw the buttons at the game over screen
function drawEndButtons()
  -- Draw restart button
  local restartX = love.graphics.getWidth() / 2 - buttonWidth / 2
  local restartY = love.graphics.getHeight() / 2 + 100
  drawButton("Restart", restartX, restartY, buttonWidth, buttonHeight)

  -- Draw exit button
  local exitX = love.graphics.getWidth() / 2 - buttonWidth / 2
  local exitY = restartY + 100
  drawButton("Exit", exitX, exitY, buttonWidth, buttonHeight)
end

-- Handle button clicks on the start menu
function handleMenuClick(x, y)
  local startX = love.graphics.getWidth() / 2 - buttonWidth / 2
  local startY = 300

  if x >= startX and x <= startX + buttonWidth and y >= startY and y <= startY + buttonHeight then
    gameState = "playing"
    gameOver = false
    points = 100
    level = 1
    gameObjects = {}
    love.mouse.setVisible(false) -- Hide cursor during gameplay
  end
end

-- Handle button clicks on the game over screen
function handleEndButtonsClick(x, y)
  -- Check restart button
  local restartX = love.graphics.getWidth() / 2 - buttonWidth / 2
  local restartY = love.graphics.getHeight() / 2 + 100

  if x >= restartX and x <= restartX + buttonWidth and y >= restartY and y <= restartY + buttonHeight then
    gameState = "menu"  -- Go back to the menu
    gameOver = false
    points = 100
    level = 1
    gameObjects = {}
    love.mouse.setVisible(true) -- Show cursor in the menu
  end

  -- Check exit button
  local exitX = love.graphics.getWidth() / 2 - buttonWidth / 2
  local exitY = restartY + 100

  if x >= exitX and x <= exitX + buttonWidth and y >= exitY and y <= exitY + buttonHeight then
    love.event.quit()  -- Exit the game
  end
end

-- Function to check if the game is over
function checkGameOver()
  if points <= 0 and not gameOver then
    gameOver = true
    points = 0
    love.mouse.setVisible(true) -- Show cursor when game is over
  end
end

-- Function to add points to the score
function addPoints(key)
  points = points + gameObjects[key].points
end

-- Handles the mouse clicks
function love.mousepressed(x, y, button, istouch, presses)
  if gameState == "menu" then
    handleMenuClick(x, y)
  elseif gameState == "playing" then
    if gameOver then
      handleEndButtonsClick(x, y)
    else
      local k = objectAt(x, y)
      if k ~= nil then
        addPoints(k)
        gameObjects[k].removing = true
        popSound:play()
      end
    end
  end
end

-- Function to draw game objects
function drawObjects()
  for key, value in ipairs(gameObjects) do
    if value.removing then
      drawRemoving(value)
    else
      drawSprite(value)
    end
  end
end

-- Draws a sprite on the screen
function drawSprite(sprite)
  love.graphics.draw(sprite.image, sprite.x, sprite.y, 0, sprite.scale, sprite.scale)
  if debug then
    love.graphics.rectangle("line", sprite.x, sprite.y, sprite.width, sprite.height)
  end
end

-- Draws a removing object with fading effect
function drawRemoving(object)
  love.graphics.setColor(1, 1, 1, object.opacity)
  drawSprite(object)
  love.graphics.setColor(1, 1, 1, 1)
  drawObjectPoints(object)
end

-- Draws the game over text
function drawGameOver()
  local text = "Game over"
  love.graphics.print(text, love.graphics.getWidth() / 2 - font:getWidth(text) / 2, love.graphics.getHeight() / 2 - font:getHeight(text) / 2)
end

-- Function to draw the current points on the screen
function drawPoints()
  love.graphics.setFont(buttonFont)
  local pointsText = "Points: " .. tostring(points)
  love.graphics.print(pointsText, 20, 20)
end

-- Function to draw the current level on the screen
function drawLevel()
  love.graphics.setFont(buttonFont)
  local levelText = "Level: " .. tostring(level)
  love.graphics.print(levelText, 20, 60)
end

-- Function to update objects' positions
function updateObjects(dt)
  for key, value in ipairs(gameObjects) do
    if not value.removing then
      value.x = value.x + value.speed * dt * level
    end
  end
end

-- Function to decrement opacity of objects being removed
function decrementOpacity()
  for key, value in ipairs(gameObjects) do
    if value.removing then
      value.opacity = value.opacity - 0.05
      if value.opacity <= 0 then
        table.remove(gameObjects, key)
      end
    end
  end
end

-- Function to update the game background
function updateBackground()
  local s = 0
  if level >= 10 then
    local d = love.math.random(0, 1)
    if d == 0 then
      d = -1
    end
    s = s + love.math.random(1, level - 10) * d
  end
  background.x = 0 + s
  background.y = 0 + s
end

-- Timer for points and object updates
function timerPointsAndObject(dt)
  pointsAndObjects = pointsAndObjects + dt
  if pointsAndObjects > shouldCreate then
    addObject()
    pointsAndObjects = pointsAndObjects - shouldCreate
  end
end

-- Timer for managing removing objects
function timerdestroyingTimer(dt)
  if destroyingTimer > 0.01 then
    destroyingTimer = destroyingTimer - 0.01
    decrementOpacity()
  end
end

-- Timer for level progression
function passLevelTimer(dt)
  levelTimer = levelTimer + dt
  if levelTimer > 1 then
    levelTimer = levelTimer - 1
    levelCountdown = levelCountdown + 1
    if levelCountdown % 10 == 0 then
      level = level + 1
    end
  end
end

-- Function to check if an object is outside the screen
function outside(x)
  return x > love.graphics.getWidth() - 100
end

-- Function to add a new object to the game
function addObject()
  local r = love.math.random(1, 100)
  local h = love.math.random(30, love.graphics.getHeight() - 100)
  if r <= 30 then
    table.insert(gameObjects, makeTrash(10, h))
  elseif r >= 60 then
    table.insert(gameObjects, makeFish(10, h))
  end
end

-- Function to create a fish object
function makeFish(x, y)
  local name = "fish" .. love.math.random(1, 3)
  local sprite = makeSprite(name, x, y, 0.4, math.min(50 * levelSpeed * love.math.random(1, 3), 80))
  sprite.points = FISH_POINTS
  table.insert(sprite.tags, "fish")
  return sprite
end

-- Function to create a trash object
function makeTrash(x, y)
  local name = "trash" .. love.math.random(1, 3)
  local sprite = makeSprite(name, x, y, 0.7, math.min(50 * levelSpeed * love.math.random(1, 3), 80))
  sprite.points = TRASH_POINTS
  table.insert(sprite.tags, "trash")
  return sprite
end

-- Function to remove points
function removePoints(key)
  if hasTag(gameObjects[key], "trash") then
    points = points - 10
  end
end

-- Function to check if an object has a certain tag
function hasTag(obj, tag)
  for _, value in ipairs(obj.tags) do
    if value == tag then
      return true
    end
  end
  return false
end

-- Function to get an object at a specific position
function objectAt(x, y)
  for key, value in ipairs(gameObjects) do
    if collide(x, y, value) and not value.removing then
      return key
    end
  end
  return nil
end

-- Function to check and manage game objects
function checkObjects()
  for i = #gameObjects, 1, -1 do
    local obj = gameObjects[i]
    if outside(obj.x) or obj.removing then
      table.remove(gameObjects, i)
    end
  end
end

-- Love2D load function
function love.load()
  love.mouse.setVisible(true) -- Cursor visible on load (menu)
  background = makeSprite("background", 0, 0)
  font = love.graphics.newFont("graphics/animeace2_reg.ttf", 50)
  love.graphics.setFont(font)
  hand = makeSprite("hand", 0, 0, 1.2)
  local music = love.audio.newSource("sounds/background.mp3", "static")
  music:play()
  popSound = love.audio.newSource("sounds/pop.ogg", "static")

  -- Button properties
  buttonFont = love.graphics.newFont(30)
end

-- Love2D update function
function love.update(dt)
  if gameState == "playing" then
    checkGameOver()
    hand.x = love.mouse.getX() - (hand.width / 2)
    hand.y = love.mouse.getY() - (hand.height / 2)
    if gamePaused or gameOver then
      return
    end
    updateBackground()
    timerPointsAndObject(dt)
    timerdestroyingTimer(dt)
    passLevelTimer(dt)
    checkObjects() -- Call checkObjects here
    updateObjects(dt)
  end
end

-- Love2D draw function
function love.draw()
  if gameState == "menu" then
    drawMenu()
  elseif gameState == "playing" then
    drawSprite(background)
    drawObjects()
    if gameOver then
      drawGameOver()
      drawEndButtons()
    end
    drawPoints()
    drawLevel()
    drawSprite(hand)
  end
end

-- Handles the key press events
function love.keypressed(k)
  if k == "escape" then
    love.event.quit()
  end
end

-- Handles the focus events
function love.focus(f)
  if not f then
    gamePaused = true
  else
    gamePaused = false
  end
end

-- Handles the quit event
function love.quit()
  print("Thanks for playing! Come back soon!")
end
