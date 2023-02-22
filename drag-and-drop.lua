local display = require("display")
local transition = require("transition")
local x = display.contentCenterX
local y = display.contentCenterY
local w = display.contentWidth
local h = display.contentHeight
local padding = 5
local frame = 25
local numSquares = 8
local transitionTime = 200
local squareWidth, squareHeight

local sceneGroup = display.newGroup()

local backgroundArea = display.newRect(sceneGroup, x, y, w - frame, h)
backgroundArea:setFillColor(0.5, 0.5, 0.8)
backgroundArea.isVisible = true

local areaBounds = backgroundArea.contentBounds

local squares = {}

local function generateSquares()
  squareWidth = backgroundArea.width - 2 * padding
  squareHeight = (backgroundArea.height - (numSquares + 1) * padding)/numSquares
  for i = 1, numSquares do
    squares[i] = display.newRect(sceneGroup, 0, 0, squareWidth, squareHeight)
    squares[i].x = backgroundArea.x
    squares[i].y = areaBounds.yMin + padding + (i - 1) * (squareHeight + padding) + squareHeight / 2
    squares[i]:setFillColor((i-1)/(numSquares-1), 0.5, 1 - (i-1)/(numSquares-1))
    squares[i].customBounds = {
        xMin = squares[i].x - squares[i].width/2,
        xMax = squares[i].x + squares[i].width/2,
        yMin = squares[i].y - squares[i].height/2,
        yMax = squares[i].y + squares[i].height/2
    }
  end
return squares
end

squares = generateSquares()

local defaultPositions = {}

for i = 1, #squares do
  defaultPositions[i] = {x = squares[i].x, y = squares[i].y}
end

local function swapSquares(s1, s2)
  local temp = squares[s1]
  squares[s1] = squares[s2]
  squares[s2] = temp
  local isDrop = s1 > s2
  for i = 1, #squares do
    local targetY = areaBounds.yMin + padding + (i - 1) * (squareHeight + padding) + squareHeight / 2
    transition.to(squares[i], {y = targetY, time = transitionTime})
    if isDrop and i >= s2 and i < s1 then
      local nearestFreeIndex = i
        for j = i-1, s2, -1 do
          if not squares[j] then
            nearestFreeIndex = j
          else
            break
          end
        end
        squares[i].customBounds = {
            xMin = squares[i].x - squares[i].width/2,
            xMax = squares[i].x + squares[i].width/2,
            yMin = areaBounds.yMin + padding + (nearestFreeIndex - 1) * (squareHeight + padding),
            yMax = areaBounds.yMin + padding + (nearestFreeIndex - 1) * (squareHeight + padding) + squareHeight
        }
        else
          squares[i].customBounds = {
            xMin = squares[i].x - squares[i].width/2,
            xMax = squares[i].x + squares[i].width/2,
            yMin = targetY - squares[i].height/2,
            yMax = targetY + squares[i].height/2
        }
        end
    end
end

local function dragSquare(event)
  local square = event.target
  local phase = event.phase
  if phase == "began" then
    display.currentStage:setFocus(square)
    square.isFocus = true
    square.y0 = event.y - square.y
    square.originalY = square.y
    event.target:toFront()
    square.y = event.y
  elseif square.isFocus then
    if phase == "moved" then
      square.y = event.y - square.y0
        for i = 1, #squares do
          local otherSquare = squares[i]
            if otherSquare ~= square then
              local otherBounds = otherSquare.customBounds
                if square.y > otherBounds.yMin and square.y < otherBounds.yMax then
                  local draggedIndex = 0
                  local overlappedIndex = 0
                  for j = 1, #squares do
                    if squares[j] == square then
                      draggedIndex = j
                    elseif squares[j] == otherSquare then
                      overlappedIndex = j
                    end
                  end
                    if draggedIndex > 0 and overlappedIndex > 0 then
                       swapSquares(draggedIndex, overlappedIndex)
                    end
                   break
                end
             end
          end
            if backgroundArea and (square.y < areaBounds.yMin or square.y > areaBounds.yMax) then
              if square.y < areaBounds.yMin + padding + squareHeight / 2 then
                square.y = areaBounds.yMin + padding + squareHeight / 2
              elseif square.y > areaBounds.yMax - padding - squareHeight / 2 then
                square.y = areaBounds.yMax - padding - squareHeight / 2
              end
            end
            elseif phase == "ended" then
              local droppedOnSquare = false
              for i = 1, #squares do
								local otherSquare = squares[i]
									if otherSquare ~= square then
										local otherBounds = otherSquare.customBounds
											if square.y > otherBounds.yMin and square.y < otherBounds.yMax then
												droppedOnSquare = true
												break
											end
									end
							end
								if not droppedOnSquare then
									local closestIndex = 1
									local closestDist = math.abs(square.y - defaultPositions[1].y)
										for i = 2, #defaultPositions do
											local dist = math.abs(square.y - defaultPositions[i].y)
												if dist < closestDist then
													closestIndex = i
													closestDist = dist
												end
										end
										local isSquareOnPosition = false
											for i = 1, #squares do
												local otherSquare = squares[i]
													if otherSquare ~= square and otherSquare.y == defaultPositions[closestIndex].y then
														isSquareOnPosition = true
														break
													end
											end
												if not isSquareOnPosition then
													square.y = defaultPositions[closestIndex].y
												else
													transition.to(square, { time = transitionTime, y = square.originalY }) -- or square.y = square.originalY
												end
											end
											display.currentStage:setFocus(nil)
											square.isFocus = false
										elseif phase == "cancelled" then
											square.y = square.originalY
											display.currentStage:setFocus(nil)
											square.isFocus = false
										end
								end
			return true
end

for i = 1, #squares do
	squares[i]:addEventListener("touch", dragSquare)
end
