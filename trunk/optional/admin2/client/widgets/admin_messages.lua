--[[**********************************
*
*	Multi Theft Auto - Admin Panel
*
*	client\widgets\admin_messages.lua
*
*	Original File by lil_Toady
*
**************************************]]

aMessagesForm = nil
_messages = nil

function aViewMessages ( player )
	if ( aMessagesForm == nil ) then
		local x, y = guiGetScreenSize()
		aMessagesForm	= guiCreateWindow ( x / 2 - 250, y / 2 - 125, 500, 250, "View Messages", false )

		aMessagesList		= guiCreateGridList ( 0.03, 0.09, 0.75, 0.85, true, aMessagesForm )
					   guiGridListAddColumn( aMessagesList, "#", 0.10 )
					   guiGridListAddColumn( aMessagesList, "Subject", 0.50 )
					   guiGridListAddColumn( aMessagesList, "Date", 0.20 )
					   guiGridListAddColumn( aMessagesList, "Author", 0.15 )
		aMessagesRead	= guiCreateButton ( 0.80, 0.20, 0.15, 0.09, "Read", true, aMessagesForm )
		aMessagesDelete	= guiCreateButton ( 0.80, 0.30, 0.15, 0.09, "Delete", true, aMessagesForm )
		aMessagesRefresh	= guiCreateButton ( 0.80, 0.65, 0.15, 0.09, "Refresh", true, aMessagesForm )
		aMessagesClose	= guiCreateButton ( 0.80, 0.85, 0.15, 0.09, "Close", true, aMessagesForm )
		addEventHandler ( "aMessage", _root, aMessagesSync )
		addEventHandler ( "onClientGUIClick", aMessagesForm, aClientMessagesClick )
		addEventHandler ( "onClientGUIDoubleClick", aMessagesForm, aClientMessagesDoubleClick )
		--Register With Admin Form
		aRegister ( "Messages", aMessagesForm, aViewMessages, aViewMessagesClose )
	end
	guiSetVisible ( aMessagesForm, true )
	guiBringToFront ( aMessagesForm )
	triggerServerEvent ( "aMessage", getLocalPlayer(), "get" )
end

function aViewMessagesClose ( destroy )
	if ( ( destroy ) or ( guiCheckBoxGetSelected ( aPerformanceMessage ) ) ) then
		if ( aMessagesForm ) then
			removeEventHandler ( "onClientGUIClick", aMessagesForm, aClientMessagesClick )
			removeEventHandler ( "onClientGUIDoubleClick", aMessagesForm, aClientMessagesDoubleClick )
			destroyElement ( aMessagesForm )
			aMessagesForm = nil
		end
	else
		if aMessagesForm then guiSetVisible ( aMessagesForm, false ) end
	end
end

function aMessagesSync ( action, data )
	if ( action == "get" ) then
		_messages = data
		guiGridListClear ( aMessagesList )
		for id, message in ipairs ( data ) do
			local row = guiGridListAddRow ( aMessagesList )
			guiGridListSetItemText ( aMessagesList, row, 1, tostring ( id ), false, false )
			if ( message.read ) then guiGridListSetItemText ( aMessagesList, row, 2, message.subject, false, false )
			else guiGridListSetItemText ( aMessagesList, row, 2, "* "..message.subject, false, false ) end
			guiGridListSetItemText ( aMessagesList, row, 3, message.time, false, false )
			guiGridListSetItemText ( aMessagesList, row, 4, message.author, false, false )
		end
	end
end

function aClientMessagesDoubleClick ( button )
	if ( button == "left" ) then
		if ( source == aMessagesList ) then
			local row = guiGridListGetSelectedItem ( aMessagesList )
			if ( row ~= -1 ) then
				local id = guiGridListGetItemText ( aMessagesList, row, 1 )
				aViewMessage ( tonumber ( id ) )
			end
		end
	end
end

function aClientMessagesClick ( button )
	if ( button == "left" ) then
		if ( source == aMessagesClose ) then
			aViewMessagesClose ( false )
		elseif ( source == aMessagesRefresh ) then
			triggerServerEvent ( "aMessage", getLocalPlayer(), "get" )
		elseif ( source == aMessagesRead ) then
			local row = guiGridListGetSelectedItem ( aMessagesList )
			if ( row == -1 ) then aMessageBox ( "Warning", "No message selected!", nil )
			else
				local id = guiGridListGetItemText ( aMessagesList, row, 1 )
				aViewMessage ( tonumber ( id ) )
			end
		elseif ( source == aMessagesDelete ) then
			local row = guiGridListGetSelectedItem ( aMessagesList )
			if ( row == -1 ) then aMessageBox ( "Warning", "No message selected!" )
			else
				local id = guiGridListGetItemText ( aMessagesList, row, 1 )
				triggerServerEvent ( "aMessage", getLocalPlayer(), "delete", tonumber ( id ) )
			end
		end
	end
end