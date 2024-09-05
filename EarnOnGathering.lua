-- Создаем фрейм для отслеживания событий
local frame = CreateFrame("Frame")

-- Создаем основное окно
local mainFrame = CreateFrame("Frame", "LootValueFrame", UIParent)
mainFrame:SetSize(240, 100) -- Размер окна (ширина 240, высота 150)
mainFrame:SetPoint("CENTER", UIParent, "CENTER") -- Положение окна

-- Добавляем фон для окна
mainFrame.bg = mainFrame:CreateTexture(nil, "BACKGROUND")
mainFrame.bg:SetAllPoints()
mainFrame.bg:SetColorTexture(0, 0, 0, 0.5) -- Черный фон с полупрозрачностью

-- Устанавливаем размеры фона, чтобы он был в 3 раза длиннее текста
local textWidth = 240 -- Ширина текстового поля
local textHeight = 40 -- Высота текстового поля
mainFrame.bg:SetSize(textWidth * 3, textHeight * 3) -- Фон в 3 раза длиннее текста и в 3 раза высоты текста

-- Добавляем текст для отображения суммы
mainFrame.text = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
mainFrame.text:SetSize(textWidth, textHeight) -- Размер текстового поля
mainFrame.text:SetPoint("TOP", mainFrame, "TOP", 0, 0) -- Устанавливаем верхнее расстояние для текстового поля
mainFrame.text:SetJustifyH("CENTER") -- Выравнивание текста по центру
mainFrame.text:SetText("Gather: 0 g 0 s") -- Начальный текст
mainFrame.text:SetTextColor(1, 1, 0) -- Цвет текста (желтый)

-- Создаем текст для отображения времени
local timerText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
timerText:SetSize(textWidth, textHeight) -- Размер текстового поля
timerText:SetPoint("TOP", mainFrame, "TOP", 0, -25) -- Устанавливаем верхнее расстояние для таймера
timerText:SetJustifyH("CENTER") -- Выравнивание текста по центру
timerText:SetText("Time: 00:00:00") -- Начальный текст времени
timerText:SetFont("Fonts\\FRIZQT__.TTF", 14) -- Размер шрифта для таймера
timerText:SetTextColor(1, 1, 0) -- Цвет текста (желтый)

-- Создаем кнопку для старта/паузы таймера
local startPauseButton = CreateFrame("Button", "StartPauseButton", mainFrame, "GameMenuButtonTemplate")
startPauseButton:SetSize(50, 30) -- Размер кнопки (ширина в 2 раза меньше)
startPauseButton:SetText("Start") -- Начальный текст на кнопке
startPauseButton:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -70, 10) -- Положение кнопки

-- Создаем кнопку для сброса времени
local resetTimeButton = CreateFrame("Button", "ResetTimeButton", mainFrame, "GameMenuButtonTemplate")
resetTimeButton:SetSize(50, 30) -- Размер кнопки (ширина в 2 раза меньше)
resetTimeButton:SetText("Reset") -- Текст на кнопке
resetTimeButton:SetPoint("RIGHT", startPauseButton, "LEFT", 110, 0) -- Положение кнопки

-- Создаем кнопку для сброса заработанных денег
local resetMoneyButton = CreateFrame("Button", "ResetMoneyButton", mainFrame, "GameMenuButtonTemplate")
resetMoneyButton:SetSize(100, 30) -- Размер кнопки
resetMoneyButton:SetText("Reset Money") -- Текст на кнопке
resetMoneyButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 10) -- Положение кнопки

-- Переменные для хранения общего количества
local totalMoney = 0
local startTime = nil
local pauseTime = nil
local timerActive = false
local timerPaused = false
local timerTicker = nil -- Переменная для хранения тикера таймера

local function UpdateGold()
    mainFrame.text:SetText(string.format(
        "Gather: %d g %d s",
        math.floor(totalMoney / 10000), math.floor(totalMoney % 10000 / 100)
    ))
end

local function UpdateTime()
    if timerActive then
        local currentTime = GetTime()
        local elapsedTime = currentTime - startTime
        local hours = math.floor(elapsedTime / 3600)
        local minutes = math.floor((elapsedTime % 3600) / 60)
        local seconds = math.floor(elapsedTime % 60)
        timerText:SetText(string.format("Time: %02d:%02d:%02d", hours, minutes, seconds))
    end
end

-- Функция для сброса всех данных
local function ResetMoney()
	totalMoney = 0
    startTime = nil
    pauseTime = nil
    timerActive = false
    timerPaused = false
    if timerTicker then
        timerTicker:Cancel()
        timerTicker = nil
    end
	UpdateGold()
end

-- Функция для сброса времени
local function ResetTime()
    startTime = nil
    pauseTime = nil
    timerActive = false
    timerPaused = false
    if timerTicker then
        timerTicker:Cancel()
        timerTicker = nil
    end
    startPauseButton:SetText("Start")
    timerText:SetText(string.format("Time: %02d:%02d:%02d", 0, 0, 0))
end

-- Функция для старта и паузы таймера
local function ToggleTimer()
    if timerActive then
        if timerPaused then
            -- Продолжить таймер
            timerPaused = false
            startPauseButton:SetText("Pause")
            -- Продолжить тикер таймера
            timerTicker = C_Timer.NewTicker(1, UpdateTime)
            startTime = startTime + (GetTime() - pauseTime) -- Корректируем startTime для учета паузы
        else
            -- Поставить на паузу
            timerPaused = true
            startPauseButton:SetText("Continue")
            -- Остановить тикер таймера
            if timerTicker then
                timerTicker:Cancel()
                timerTicker = nil
            end
            pauseTime = GetTime()
        end
    else
        -- Запустить таймер
        timerActive = true
        startTime = GetTime()
        timerPaused = false
        startPauseButton:SetText("Pause")
        timerTicker = C_Timer.NewTicker(1, UpdateTime)
    end
end

-- Функция для обработки событий
local function OnEvent(self, event, ...)
    if event == "LOOT_READY" then
        -- Сначала убираем предыдущие сообщения
        if self.lastLootTime and GetTime() - self.lastLootTime < 1 then
            -- Если событие срабатывает слишком часто, игнорируем его
            return
        end
        self.lastLootTime = GetTime()
        
        -- Получаем количество предметов в луте
        local numberOfItems = GetNumLootItems()
        local totalValue = 0

        -- Уникальный идентификатор для вашего аддона
        local callerID = "EarnOnGathering"

        for i = 1, numberOfItems do
            -- Получаем информацию о предмете
            local itemLink = GetLootSlotLink(i)
            local itemIcon, itemName, itemQuantity, currencyID, itemQuality, locked, isQuestItem, isActiveQuest, isArtifactPower = GetLootSlotInfo(i)

            if itemLink and itemQuantity > 0 then
                -- Получаем цену на аукционе с помощью API Auctionator
                local price = Auctionator.API.v1.GetAuctionPriceByItemLink(callerID, itemLink)
                
                -- Проверяем, вернула ли функция цену
                if price then
                    totalValue = totalValue + (price * itemQuantity)
                end
            end
        end

        -- Преобразуем общую стоимость в золото и серебро
        totalMoney = totalMoney + totalValue
        -- Обновляем отображение
        UpdateGold()
    end
end



-- Регистрируем событие открытия лута
frame:RegisterEvent("LOOT_READY")
frame:SetScript("OnEvent", OnEvent)

-- Переменные для перетаскивания
local isDragging = false

-- Функция начала перетаскивания
local function OnDragStart(self)
    isDragging = true
    self:StartMoving()
end

-- Функция окончания перетаскивания
local function OnDragStop(self)
    isDragging = false
    self:StopMovingOrSizing()
end

-- Обработка перемещения окна
mainFrame:SetMovable(true)
mainFrame:SetClampedToScreen(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", OnDragStart)
mainFrame:SetScript("OnDragStop", OnDragStop)

-- Устанавливаем обработчики для кнопок
resetMoneyButton:SetScript("OnClick", ResetMoney)
resetTimeButton:SetScript("OnClick", ResetTime)
startPauseButton:SetScript("OnClick", ToggleTimer)

-- Обновляем отображение при запуске аддона
UpdateTime()
UpdateGold()