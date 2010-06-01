--[[****************************************************************************
  * _NPCScan by Saiket                                                         *
  * _NPCScan.Config.Search.lua - Adds a configuration pane to add/remove NPCs  *
  *   and achievements to search for.                                          *
  ****************************************************************************]]


local _NPCScan = _NPCScan;
local L = _NPCScanLocalization;
local me = CreateFrame( "Frame" );
_NPCScan.Config.Search = me;

me.TableContainer = CreateFrame( "Frame", nil, me );

me.InactiveAlpha = 0.5;

local LibRareSpawnsData;
if ( IsAddOnLoaded( "LibRareSpawns" ) ) then
	LibRareSpawnsData = LibRareSpawns.ByNPCID;
end




--[[****************************************************************************
  * Function: _NPCScan.Config.Search.AchievementAddFoundOnClick                *
  ****************************************************************************]]
function me.AchievementAddFoundOnClick ( Enable )
	if ( _NPCScan.SetAchievementsAddFound( Enable == "1" ) ) then
		_NPCScan.CacheListPrint( true );
	end
end




local function GetWorldIDName ( WorldID ) -- Converts a WorldID into a localized world name
	return type( WorldID ) == "number" and select( WorldID, GetMapContinents() ) or WorldID;
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search.TabSelect                                 *
  * Description: Selects the given tab.                                        *
  ****************************************************************************]]
function me.TabSelect ( NewTab )
	local OldTab = me.TabSelected;
	if ( NewTab ~= OldTab ) then
		if ( OldTab ) then
			if ( OldTab.Deactivate ) then
				OldTab:Deactivate();
			end
			PanelTemplates_DeselectTab( OldTab );
		end

		for _, Row in ipairs( me.Table.Rows ) do
			Row:SetAlpha( 1.0 );
		end
		me.Table:Clear();

		me.TabSelected = NewTab;
		PanelTemplates_SelectTab( NewTab );
		if ( NewTab.Activate ) then
			NewTab:Activate();
		end
		NewTab:Update();
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TabOnClick                                *
  ****************************************************************************]]
function me:TabOnClick ()
	PlaySound( "igCharacterInfoTab" );
	me.TabSelect( self );
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TabOnEnter                                *
  ****************************************************************************]]
function me:TabOnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT", 0, -8 );
	if ( self.AchievementID ) then
		local _, Name, _, _, _, _, _, Description = GetAchievementInfo( self.AchievementID );
		local WorldID = _NPCScan.Achievements[ self.AchievementID ].WorldID;
		local Highlight = HIGHLIGHT_FONT_COLOR;
		if ( WorldID ) then
			GameTooltip:ClearLines();
			local Gray = GRAY_FONT_COLOR;
			GameTooltip:AddDoubleLine( Name, L.SEARCH_WORLD_FORMAT:format( GetWorldIDName( WorldID ) ),
				Highlight.r, Highlight.g, Highlight.b, Gray.r, Gray.g, Gray.b );
		else
			GameTooltip:SetText( Name, Highlight.r, Highlight.g, Highlight.b );
		end
		GameTooltip:AddLine( Description, nil, nil, nil, true );

		if ( not _NPCScan.OptionsCharacter.Achievements[ self.AchievementID ] ) then
			local Color = RED_FONT_COLOR;
			GameTooltip:AddLine( L.SEARCH_ACHIEVEMENT_DISABLED, Color.r, Color.g, Color.b );
		end
	else
		GameTooltip:SetText( L.SEARCH_NPCS_DESC, nil, nil, nil, nil, true );
	end
	GameTooltip:Show();
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TabCheckOnClick                           *
  ****************************************************************************]]
function me:TabCheckOnClick ()
	local Enable = self:GetChecked();
	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );

	local AchievementID = self:GetParent().AchievementID;
	me.AchievementSetEnabled( AchievementID, Enable );
	if ( not Enable ) then
		_NPCScan.AchievementRemove( AchievementID );
	elseif ( _NPCScan.AchievementAdd( AchievementID ) ) then -- Cache might have changed
		_NPCScan.CacheListPrint( true );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TabCheckOnEnter                           *
  ****************************************************************************]]
function me:TabCheckOnEnter ()
	me.TabOnEnter( self:GetParent() );
end




local Tabs = {}; -- [ "NPC" or AchievementID ] = Tab;
--[[****************************************************************************
  * Function: _NPCScan.Config.Search.NPCValidateButtons                        *
  * Description: Validates ability to use add and remove buttons.              *
  ****************************************************************************]]
function me.NPCValidateButtons ()
	local NpcID = me.EditBoxID:GetText() ~= "" and me.EditBoxID:GetNumber() or nil;
	local Name = me.EditBoxName:GetText():trim():lower();
	Name = Name ~= "" and Name or nil;

	local CanRemove = _NPCScan.OptionsCharacter.NPCs[ NpcID ];
	local CanAdd = Name and NpcID and Name ~= CanRemove and NpcID >= 1 and NpcID <= _NPCScan.IDMax;

	if ( me.Table ) then
		me.Table:SetSelectionByKey( CanRemove and NpcID or nil );
	end
	me.AddButton[ CanAdd and "Enable" or "Disable" ]( me.AddButton );
	me.RemoveButton[ CanRemove and "Enable" or "Disable" ]( me.RemoveButton );
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search.NPCAdd                                    *
  * Description: Adds a Custom NPC list element.                               *
  ****************************************************************************]]
function me.NPCAdd ()
	local NpcID, Name = me.EditBoxID:GetNumber(), me.EditBoxName:GetText();
	if ( _NPCScan.TamableIDs[ NpcID ] ) then
		_NPCScan.Print( L.SEARCH_ADD_TAMABLE_FORMAT:format( Name ) );
	end
	_NPCScan.NPCRemove( NpcID );
	if ( _NPCScan.NPCAdd( NpcID, Name ) ) then
		_NPCScan.CacheListPrint( true );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search.NPCRemove                                 *
  * Description: Removes a Custom NPC list element.                            *
  ****************************************************************************]]
function me.NPCRemove ()
	_NPCScan.NPCRemove( me.EditBoxID:GetNumber() );
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:NPCOnSelect                               *
  * Description: Updates the edit boxes when a table row is selected.          *
  ****************************************************************************]]
function me:NPCOnSelect ( NpcID )
	if ( NpcID ~= nil ) then
		me.EditBoxID:SetText( NpcID );
		me.EditBoxName:SetText( _NPCScan.OptionsCharacter.NPCs[ NpcID ] );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:NPCUpdate                                 *
  ****************************************************************************]]
function me:NPCUpdate ()
	me.EditBoxID:SetText( "" );
	me.EditBoxName:SetText( "" );

	local WorldIDs = _NPCScan.OptionsCharacter.NPCWorldIDs;
	for NpcID, Name in pairs( _NPCScan.OptionsCharacter.NPCs ) do
		local Row = me.Table:AddRow( NpcID,
			L[ _NPCScan.TestID( NpcID ) and "SEARCH_CACHED_YES" or "SEARCH_CACHED_NO" ],
			Name, NpcID, GetWorldIDName( WorldIDs[ NpcID ] ) );

		if ( not _NPCScan.NPCIsActive( NpcID ) ) then
			Row:SetAlpha( me.InactiveAlpha );
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:NPCActivate                               *
  ****************************************************************************]]
function me:NPCActivate ()
	me.Table:SetHeader( L.SEARCH_CACHED, L.SEARCH_NAME, L.SEARCH_ID, L.SEARCH_WORLD );
	me.Table:SetSortHandlers( true, true, true, true );
	me.Table:SetSortColumn( 2 ); -- Default by name

	me.NPCControls:Show();
	me.TableContainer:SetPoint( "BOTTOM", me.NPCControls, "TOP", 0, 4 );
	me.Table.OnSelect = me.NPCOnSelect;
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:NPCDeactivate                             *
  ****************************************************************************]]
function me:NPCDeactivate ()
	me.NPCControls:Hide();
	me.TableContainer:SetPoint( "BOTTOM", me.NPCControls );
	me.Table.OnSelect = nil;
end




--[[****************************************************************************
  * Function: _NPCScan.Config.Search.AchievementSetEnabled                     *
  * Description: Enables/disables the achievement related to a tab.            *
  ****************************************************************************]]
function me.AchievementSetEnabled ( AchievementID, Enable )
	local Tab = Tabs[ AchievementID ];
	Tab.Checkbox:SetChecked( Enable );
	local Texture = Tab.Checkbox:GetCheckedTexture();
	Texture:SetTexture( Enable
		and [[Interface\Buttons\UI-CheckBox-Check]]
		or [[Interface\RAIDFRAME\ReadyCheck-NotReady]] );
	Texture:Show();

	-- Update tooltip if shown
	if ( GameTooltip:GetOwner() == Tab ) then
		me.TabOnEnter( Tab );
	end

	if ( me.TabSelected == Tab ) then
		me.Table.Header:SetAlpha( Enable and 1.0 or me.InactiveAlpha );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:AchievementUpdate                         *
  ****************************************************************************]]
function me:AchievementUpdate ()
	local Achievement = _NPCScan.Achievements[ self.AchievementID ];
	for CriteriaID, NpcID in pairs( Achievement.Criteria ) do
		local Name, _, Completed = GetAchievementCriteriaInfo( CriteriaID );

		local Row = me.Table:AddRow( CriteriaID,
			L[ _NPCScan.TestID( NpcID ) and "SEARCH_CACHED_YES" or "SEARCH_CACHED_NO" ],
			Name, NpcID,
			L[ Completed and "SEARCH_COMPLETED_YES" or "SEARCH_COMPLETED_NO" ] );

		if ( not _NPCScan.AchievementNPCIsActive( Achievement, NpcID ) ) then
			Row:SetAlpha( me.InactiveAlpha );
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:AchievementActivate                       *
  ****************************************************************************]]
function me:AchievementActivate ()
	me.Table:SetHeader( L.SEARCH_CACHED, L.SEARCH_NAME, L.SEARCH_ID, L.SEARCH_COMPLETED );
	me.Table:SetSortHandlers( true, true, true, true );
	me.Table:SetSortColumn( 2 ); -- Default by name

	me.Table.Header:SetAlpha( _NPCScan.OptionsCharacter.Achievements[ self.AchievementID ] and 1.0 or me.InactiveAlpha );
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:AchievementDeactivate                     *
  ****************************************************************************]]
function me:AchievementDeactivate ()
	me.Table.Header:SetAlpha( 1.0 );
end




--[[****************************************************************************
  * Function: _NPCScan.Config.Search.UpdateTab                                 *
  * Description: Updates the table for a given tab if it is displayed.         *
  ****************************************************************************]]
do
	local function OnUpdate ( self ) -- Recreates table data at most once per frame
		self:SetScript( "OnUpdate", nil );

		for _, Row in ipairs( self.Table.Rows ) do
			Row:SetAlpha( 1.0 );
		end
		self.Table:Clear();
		self.TabSelected:Update();
	end
	function me.UpdateTab ( ID )
		if ( not ID or Tabs[ ID ] == me.TabSelected ) then
			me:SetScript( "OnUpdate", OnUpdate );
		end;
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TableRowOnEnter                           *
  * Description: Adds mob info from LibRareSpawns.                             *
  ****************************************************************************]]
if ( LibRareSpawnsData ) then
	local MaxSize = 160; -- Larger images are forced to this max width and height
	function me:TableRowOnEnter ()
		local Data = LibRareSpawnsData[ self:GetData() ];
		if ( Data ) then
			local Width, Height = Data.PortraitWidth, Data.PortraitHeight;
			if ( Width > MaxSize ) then
				Width, Height = MaxSize, Height * ( MaxSize / Width );
			end
			if ( Height > MaxSize ) then
				Width, Height = Width * ( MaxSize / Height ), MaxSize;
			end

			GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
			GameTooltip:SetText( L.SEARCH_IMAGE_FORMAT:format( Data.Portrait, Height, Width ) );
			GameTooltip:AddLine( L.SEARCH_LEVEL_TYPE_FORMAT:format( Data.Level, Data.MonsterType ) );
			GameTooltip:Show();
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TableCreateRow                            *
  ****************************************************************************]]
do
	local CreateRowBackup;
	if ( LibRareSpawnsData ) then
		local function AddTooltipHooks( Row, ... )
			Row:SetScript( "OnEnter", me.TableRowOnEnter );
			Row:SetScript( "OnLeave", GameTooltip_Hide );

			return Row, ...;
		end
		function me:TableCreateRow ( ... )
			return AddTooltipHooks( CreateRowBackup( self, ... ) );
		end
	end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:TableCreate                               *
  ****************************************************************************]]
	function me:TableCreate ()
		-- Note: Keep late bound so _NPCScan.Overlay can hook into the table as it's created
		if ( not self.Table ) then
			self.Table = LibStub( "LibTextTable-1.0" ).New( nil, self.TableContainer );
			self.Table:SetAllPoints();

			if ( LibRareSpawnsData ) then
				-- Hook row creation to add mouseover tooltips
				CreateRowBackup = self.Table.CreateRow;
				self.Table.CreateRow = self.TableCreateRow;
			end

			return self.Table;
		end
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:OnShow                                    *
  ****************************************************************************]]
function me:OnShow ()
	if ( not me.Table ) then
		me:TableCreate();
	end

	if ( me.TabSelected ) then
		me.UpdateTab();
	else
		me.TabSelect( Tabs[ "NPC" ] );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Config.Search:default                                   *
  ****************************************************************************]]
function me:default ()
	_NPCScan.Synchronize( _NPCScan.Options ); -- Resets only character settings
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.SEARCH_TITLE;
	me.parent = L.CONFIG_TITLE;
	me:Hide();
	me:SetScript( "OnShow", me.OnShow );

	-- Pane title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	me.Title:SetPoint( "TOPLEFT", 16, -16 );
	me.Title:SetText( L.SEARCH_TITLE );
	local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
	me.SubText = SubText;
	SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
	SubText:SetPoint( "RIGHT", -32, 0 );
	SubText:SetHeight( 32 );
	SubText:SetJustifyH( "LEFT" );
	SubText:SetJustifyV( "TOP" );
	SubText:SetText( L.SEARCH_DESC );


	-- Settings checkboxes
	local AddFoundCheckbox = CreateFrame( "CheckButton", "_NPCScanSearchAchievementAddFoundCheckbox", me, "InterfaceOptionsCheckButtonTemplate" );
	me.AddFoundCheckbox = AddFoundCheckbox;
	AddFoundCheckbox:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -8 );
	AddFoundCheckbox.setFunc = me.AchievementAddFoundOnClick;
	AddFoundCheckbox.tooltipText = L.SEARCH_ACHIEVEMENTADDFOUND_DESC;
	local Label = _G[ AddFoundCheckbox:GetName().."Text" ];
	Label:SetText( L.SEARCH_ACHIEVEMENTADDFOUND );
	AddFoundCheckbox:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );


	-- Controls for NPCs table
	local NPCControls = CreateFrame( "Frame", nil, me );
	me.NPCControls = NPCControls;
	NPCControls:Hide();

	-- Create add and remove buttons
	local RemoveButton = CreateFrame( "Button", nil, NPCControls, "GameMenuButtonTemplate" );
	me.RemoveButton = RemoveButton;
	RemoveButton:SetSize( 16, 20 );
	RemoveButton:SetPoint( "BOTTOMRIGHT", me, -16, 16 );
	RemoveButton:SetText( L.SEARCH_REMOVE );
	RemoveButton:SetScript( "OnClick", me.NPCRemove );
	local AddButton = CreateFrame( "Button", nil, NPCControls, "GameMenuButtonTemplate" );
	me.AddButton = AddButton;
	AddButton:SetSize( 16, 20 );
	AddButton:SetPoint( "BOTTOMRIGHT", RemoveButton, "TOPRIGHT", 0, 4 );
	AddButton:SetText( L.SEARCH_ADD );
	AddButton:SetScript( "OnClick", me.NPCAdd );

	-- Create edit boxes
	local LabelName = NPCControls:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.LabelName = LabelName;
	LabelName:SetPoint( "BOTTOMLEFT", me, 16, 16 );
	LabelName:SetPoint( "TOP", RemoveButton );
	LabelName:SetText( L.SEARCH_NAME );
	local LabelID = NPCControls:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.LabelID = LabelID;
	LabelID:SetPoint( "BOTTOMLEFT", LabelName, "TOPLEFT", 0, 4 );
	LabelID:SetPoint( "TOP", AddButton );
	LabelID:SetText( L.SEARCH_ID );

	local EditBoxName = CreateFrame( "EditBox", "_NPCScanSearchName", NPCControls, "InputBoxTemplate" );
	me.EditBoxName = EditBoxName;
	local EditBoxID = CreateFrame( "EditBox", "_NPCScanSearchID", NPCControls, "InputBoxTemplate" );
	me.EditBoxID = EditBoxID;

	EditBoxName:SetPoint( "TOP", LabelName );
	EditBoxName:SetPoint( "LEFT", -- Attach to longest label
		LabelName:GetStringWidth() > LabelID:GetStringWidth() and LabelName or LabelID,
		"RIGHT", 8, 0 );
	EditBoxName:SetPoint( "BOTTOMRIGHT", RemoveButton, "BOTTOMLEFT", -4, 0 );
	EditBoxName:SetAutoFocus( false );
	EditBoxName:SetScript( "OnTabPressed", function () EditBoxID:SetFocus(); end );
	EditBoxName:SetScript( "OnEnterPressed", function () AddButton:Click(); end );
	EditBoxName:SetScript( "OnTextChanged", me.NPCValidateButtons );
	EditBoxName:SetScript( "OnEnter", _NPCScan.Config.ControlOnEnter );
	EditBoxName:SetScript( "OnLeave", GameTooltip_Hide );
	EditBoxName.tooltipText = L.SEARCH_NAME_DESC;

	EditBoxID:SetPoint( "TOP", LabelID );
	EditBoxID:SetPoint( "LEFT", EditBoxName );
	EditBoxID:SetPoint( "BOTTOMRIGHT", EditBoxName, "TOPRIGHT" );
	EditBoxID:SetAutoFocus( false );
	EditBoxID:SetNumeric( true );
	EditBoxID:SetMaxLetters( floor( log10( _NPCScan.IDMax ) ) + 1 );
	EditBoxID:SetScript( "OnTabPressed", function () EditBoxName:SetFocus(); end );
	EditBoxID:SetScript( "OnEnterPressed", function () AddButton:Click(); end );
	EditBoxID:SetScript( "OnTextChanged", me.NPCValidateButtons );
	EditBoxID:SetScript( "OnEnter", _NPCScan.Config.ControlOnEnter );
	EditBoxID:SetScript( "OnLeave", GameTooltip_Hide );
	EditBoxID.tooltipText = L.SEARCH_ID_DESC;

	NPCControls:SetPoint( "BOTTOMRIGHT", RemoveButton );
	NPCControls:SetPoint( "LEFT", LabelID );
	NPCControls:SetPoint( "TOP", AddButton );


	-- Place table
	me.TableContainer:SetPoint( "TOP", AddFoundCheckbox, "BOTTOM", 0, -28 );
	me.TableContainer:SetPoint( "LEFT", SubText, -2, 0 );
	me.TableContainer:SetPoint( "RIGHT", -16, 0 );
	me.TableContainer:SetPoint( "BOTTOM", NPCControls );
	me.TableContainer:SetBackdrop( { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"; } );

	-- Add all tabs
	local LastTab;
	local TabCount = 0;
	local function AddTab ( ID, Update, Activate, Deactivate )
		TabCount = TabCount + 1;
		local Tab = CreateFrame( "Button", "_NPCScanSearchTab"..TabCount, me.TableContainer, "TabButtonTemplate" );
		Tabs[ ID ] = Tab;

		Tab:SetHitRectInsets( 6, 6, 6, 0 );
		Tab:SetScript( "OnClick", me.TabOnClick );
		Tab:SetScript( "OnEnter", me.TabOnEnter );
		Tab:SetScript( "OnLeave", GameTooltip_Hide );
		Tab:SetMotionScriptsWhileDisabled( true ); -- Allow tooltip while active

		if ( type( ID ) == "number" ) then -- AchievementID
			local Size = select( 2, Tab:GetFontString():GetFont() ) + 4;
			Tab:SetText( "|T:"..Size.."|t"..select( 2, GetAchievementInfo( ID ) ) );
			Tab.AchievementID = ID;
			local Checkbox = CreateFrame( "CheckButton", nil, Tab, "UICheckButtonTemplate" );
			Tab.Checkbox = Checkbox;
			Checkbox:SetSize( Size + 2, Size + 2 );
			Checkbox:SetPoint( "LEFT", _G[ Tab:GetName().."Text" ], -4, 0 );
			Checkbox:SetHitRectInsets( 4, 4, 4, 4 );
			Checkbox:SetScript( "OnClick", me.TabCheckOnClick );
			Checkbox:SetScript( "OnEnter", me.TabCheckOnEnter );
			Checkbox:SetScript( "OnLeave", GameTooltip_Hide );
			me.AchievementSetEnabled( ID, false ); -- Initialize the custom "unchecked" texture
		else
			Tab:SetText( L.SEARCH_NPCS );
		end
		PanelTemplates_TabResize( Tab, -8 );

		Tab.Update = Update;
		Tab.Activate = Activate;
		Tab.Deactivate = Deactivate;

		PanelTemplates_DeselectTab( Tab );
		if ( LastTab ) then
			Tab:SetPoint( "LEFT", LastTab, "RIGHT", -4, 0 );
		else
			Tab:SetPoint( "BOTTOMLEFT", me.TableContainer, "TOPLEFT" );
		end
		LastTab = Tab;
	end
	AddTab( "NPC", me.NPCUpdate, me.NPCActivate, me.NPCDeactivate );
	for AchievementID in pairs( _NPCScan.Achievements ) do
		AddTab( AchievementID, me.AchievementUpdate, me.AchievementActivate, me.AchievementDeactivate );
	end


	InterfaceOptions_AddCategory( me );
end