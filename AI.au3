#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/sf
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/sv
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <MsgBoxConstants.au3>
#include <Misc.au3>
#include <ImageSearch.au3>
#include <Array.au3>
#include <File.au3>
#include <ScreenCapture.au3>
;uses a* implementation for autoit3 by toady https://www.autoitscript.com/forum/topic/47161-artificial-intelligence-bot-path-finding/
Global $Paused
Global $eX
Global $eY
Global $pX
Global $pY
Global $homeX
Global $homeY
Global $gridX[6]
Global $gridY[8]
Global $mPos
Global $x1
Global $y1
Global $search = 0
Global $map[6][8]
Global $sourceGraph[6][8] ;keep track of source node locations
Global $closedList_Str
Global $openList_Str
Global $heuristic = 1 ;1 = manhattan distance, 0 = euclidean
Global $allow_diagonals_Boolean = 0
Global $estimate = 1
Global $allow_overestimate = 0
Global $closedList_Str = "_"
Global $openList_Str = "_"
Global $gameOver = 0
Global $reset
Global $resetNodes[6][2]
Global $runCount
Global $battleFlag
Global $sourceNodes[6][2]
Global $mapCheck = 0 ;check if map is learned/valid
Global $mapToRun
Global $metalFlag = 0
HotKeySet("{INSERT}", "trainImage")
HotKeySet("{End}", "TogglePause")
HotKeySet("{Home}", "Stop")

While $mapCheck = 0
	$mapToRun = InputBox("Notice", "Enter Map to Run", "")
	$mapCheck = 1
	Local $CheckFolder = _FileListToArray(@ScriptDir, $mapToRun)
	If @error = 4 Then
		MsgBox($MB_SYSTEMMODAL, "", "Map not valid.")
		$mapCheck = 0
	EndIf
	If $mapToRun = "Metal" Then
		$metalFlag = 1
	EndIf
WEnd

;FileOpen("debug.txt", 2)
;FileClose("debug.txt")
;FileOpen("debug.txt")
For $i = 0 To 5
	For $j = 0 To 7
		$map[$i][$j] = "0"
	Next
Next
For $i = 0 To 5
	For $j = 0 To 1
		$sourceNodes[$i][$j] = 0
	Next
Next
$resetNodes = $sourceNodes
$reset = $map
Global $maxRuns = InputBox("Check", "Enter % to gain", "")
If @error Then Exit
MsgBox(0, "Notice", "Click Ok to start.")
;graphPrint($map)
$search = _ImageSearch("home.png", 1, $homeX, $homeY, 95)
$pX = $homeX - 245
$pY = $homeY + 25
For $i = 0 To 5 ;constr grid
	$gridX[$i] = $pX + ($i * 80) + 45
Next
For $i = 0 To 7
	$gridY[$i] = $pY - ($i * 80) - 200
Next

Sleep(2000)
;=====================================================================================================================
;main
;Loop until n% gained
;=====================================================================================================================
While ($runCount < $maxRuns * 2)

	If _ImageSearchArea("battle.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 100) Then $battleFlag = 1
	;=====================================================================================================================
	;menu state1
	;=====================================================================================================================
	While ($battleFlag = 0 And $metalFlag = 1) ;main menu
		If _ImageSearchArea("battle.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 100) Then $battleFlag = 1
		$gameOver = 0 ;set state to ending
		For $i = 0 To 3
			scrollUp()
		Next
		Sleep(1000)
		MouseMove($homeX, $homeY - 750, 3) ;click button
		MouseClick("left")
		Sleep(1000)
		MouseMove($pX + 125, $pY - 200, 3) ;click start
		MouseClick("left")
		Sleep(3000)
		MouseMove($pX + 75, $pY - 965, 3) ; click skip
		MouseClick("left")
		Sleep(250)
		MouseClick("left")
		Sleep(6000)
		If _ImageSearchArea("battle.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 100) Then $battleFlag = 1
		;Loop through stages until complete
	WEnd
	;=====================================================================================================================
	;menu state2
	;=====================================================================================================================
	While ($battleFlag = 0 And $metalFlag = 0) ;running normal map
		If _ImageSearchArea("battle.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 100) Then $battleFlag = 1
		$gameOver = 0
		Local $numberFile = StringRight($mapToRun, 1)
		Local $x3
		Local $y3
		Local $numbers = _FileListToArray(@ScriptDir & "\Numbers", $numberFile & ".png")
		Local $tempNumber = _ImageSearchArea(@ScriptDir & "\Numbers\" & $numbers[1], 1, $pX, $pY - 1000, $pX + 500, $pY, $x3, $y3, 100)
		If $tempNumber = 1 Then
			MouseMove($x3 + 100, $y3, 3)
			Sleep(250)
			MouseClick("left")
		Else
			scrollUp()
			Local $tempNumber = _ImageSearchArea(@ScriptDir & "\Numbers\" & $numbers[1], 1, $pX, $pY - 1000, $pX + 500, $pY, $x3, $y3, 100)
			If $tempNumber = 1 Then
				MouseMove($x3 + 100, $y3, 3)
				Sleep(250)
				MouseClick("left")
			EndIf
		EndIf
		Sleep(3000)
		MouseMove($pX + 125, $pY - 200, 3) ;click start
		MouseClick("left")
		Sleep(3000)
		MouseMove($pX + 75, $pY - 965, 3) ; click skip
		MouseClick("left")
		Sleep(250)
		MouseClick("left")
		Sleep(6000)
		If _ImageSearchArea("battle.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 100) Then $battleFlag = 1
	WEnd
	;=====================================================================================================================
	;battle state
	;=====================================================================================================================

	$stepCount = 0
	While ($gameOver = 0) ;state set to in battle
		While ($stepCount > 9 And $metalFlag = 1) ;if takes 10 steps to solve, move randomly to end game quickly
			scramble()
			Sleep(5000)
			If (_ImageSearchArea("end.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 95) = 1 Or _ImageSearchArea("video.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 35) = 1 Or _ImageSearchArea("hint.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 35) = 1) Then
				$gameOver = 1
				$battleFlag = 0
				MouseClick("left", $homeX, $homeY - 530, 2, 10)
				MouseMove($homeX, $pY - 980, 3)
				For $i = 0 To 60
					Sleep(500)
					MouseClick("left")
				Next
				$runCount = $runCount + 1
			EndIf
			ExitLoop (2)
		WEnd
		$stepCount = $stepCount + 1
		$sourceNodes = $resetNodes
		$map = $reset ;reset graph
		$map = setEnemies($map)
		If $metalFlag = 1 Then
			$map = setTraps($map, "0")
		Else
			$map = setTraps($map, "4")
		EndIf
		$sourceNodes = allyCheck($sourceNodes) ;get source nodes

		$rowNodes = sequenceMap($map) ;get sink nodes
		$colNodes = sequenceMapCol($map)

		$l1 = getLength($rowNodes, 1)
		$l2 = getLength($colNodes, 1)

		If ($l1[0] > $l2[0]) Then ;solve with row/col, whichever has more enemies
			$headNodes = getHeads($rowNodes, 2, 0) ;[2][2]	;separate heads and tails
			$tailNodes = getTails($rowNodes, 2, 0)
			If popCol($sourceNodes, 1, 2)[0] = popCol($headNodes, 0, 2)[0] And popCol($sourceNodes, 1, 2)[1] = popCol($headNodes, 0, 2)[1] Then
				$temp = popCol($sourceNodes, 0, 2)
				$temp2 = popCol($tailNodes, 0, 2)
				If (Abs($temp[0] - $temp2[0]) + Abs($temp[1] - $temp2[1])) = 1 Then
					MouseMove($gridX[$temp[0]], $gridY[$temp[1]], 2)
					MouseDown("left")
					Sleep(500)
					MouseMove($gridX[$temp2[0]], $gridY[$temp2[1]], 2)
					MouseUp("left")
				Else
					$map = setBlock($map, popCol($tailNodes, 0, 2)[0], popCol($headNodes, 0, 2)[1])
					$path = getPath($map, popCol($sourceNodes, 0, 2), $temp2)
					movePiece($path, $sourceNodes, 0)
				EndIf
			Else
				$path = getPath($map, popCol($sourceNodes, 1, 2), popCol($headNodes, 0, 2))
				shiftPiece($path, $sourceNodes, 0, $map, 1, popCol($tailNodes, 0, 2))
			EndIf
		Else
			$colHeadNodes = getHeads($colNodes, 2, 1)
			$colTailNodes = getTails($colNodes, 2, 1)
			If popCol($sourceNodes, 1, 2)[0] = popCol($colHeadNodes, 0, 2)[0] And popCol($sourceNodes, 1, 2)[1] = popCol($colHeadNodes, 0, 2)[1] Then
				$temp = popCol($sourceNodes, 0, 2)
				$temp2 = popCol($colTailNodes, 0, 2)
				If Abs($temp[0] - $temp2[0]) + Abs($temp[1] - $temp2[1]) = 1 Then
					MouseMove($gridX[$temp[0]], $gridY[$temp[1]], 2)
					MouseDown("left")
					Sleep(500)
					MouseMove($gridX[$temp2[0]], $gridY[$temp2[1]], 2)
					MouseUp("left")
				Else
					$map = setBlock($map, popCol($colTailNodes, 0, 2)[0], popCol($colHeadNodes, 0, 2)[1])
					$path = getPath($map, popCol($sourceNodes, 0, 2), $temp2)
					movePiece($path, $sourceNodes, 0)
				EndIf
			Else
				$path = getPath($map, popCol($sourceNodes, 1, 2), popCol($colHeadNodes, 0, 2))
				shiftPiece($path, $sourceNodes, 0, $map, 1, popCol($colTailNodes, 0, 2))
			EndIf
		EndIf

		MouseMove($homeX, $pY - 980, 3)
		Sleep(10000)
		If (_ImageSearchArea("end.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 95) = 1 Or _ImageSearchArea("video.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 35) = 1 Or _ImageSearchArea("hint.png", 1, $pX, $pY - 1000, $pX + 500, $pY, $eX, $eY, 35) = 1) Then
			$gameOver = 1 ;set state to game over
			$battleFlag = 0
			MouseClick("left", $homeX, $homeY - 530, 2, 10)
			MouseMove($homeX, $pY - 980, 3)
			For $i = 0 To 60
				Sleep(500)
				MouseClick("left")
			Next
			$runCount = $runCount + 1
		EndIf
	WEnd
WEnd ;==>main
;=============================================================================
; Adds nodes the a list
;=============================================================================
Func _Add_List(ByRef $list, $node)
	ReDim $list[UBound($list) + 1]
	$list[UBound($list) - 1] = $node
EndFunc   ;==>_Add_List
;=============================================================================
; Adds adjacent nodes to the open list if:
; 1. Node is not a barrier "x"
; 2. Node is not in open list
; 3. Node is not in closed list
; Set newly added node's parent to the current node and update its F,G, and H
; Only need to check North, South, East and West nodes.
;=============================================================================
Func _AddAdjacents_Openlist(ByRef $data, ByRef $openlist, ByRef $closedlist, ByRef $node, ByRef $goal)
	Local $current_coord = StringSplit($node[0], ",")
	Local $x = $current_coord[1]
	Local $y = $current_coord[2]
	Local $h ; heuristic
	Local $north = 0
	Local $south = 0
	Local $east = 0
	Local $west = 0
	Local $obj = $data[$x][$y - 1]
	If $obj[5] <> "x" And _ ;north
			Not _IsInAnyList($obj[0]) Then ;If not in closed list or openlist and is not a barrier
		If $heuristic = 1 Then
			$h = _MD($obj, $goal)
		Else
			$h = _ED($obj, $goal)
		EndIf
		$obj[1] = $node[0] ;set nodes parent to last node
		$obj[3] = $node[3] + $obj[3] ;set g score (current node's G score + adjacent node's G score)
		$obj[2] = $obj[3] + $h ;set f = g + h score
		$data[$x][$y - 1] = $obj
		$north = 1
		$openList_Str &= $obj[0] & "_"
		_Insert_PQ($openlist, $obj)
	EndIf
	$obj = $data[$x][$y + 1]
	If $obj[5] <> "x" And _ ;south
			Not _IsInAnyList($obj[0]) Then
		If $heuristic = 1 Then
			$h = _MD($obj, $goal)
		Else
			$h = _ED($obj, $goal)
		EndIf
		$obj[1] = $node[0] ;set nodes parent to last node
		$obj[3] = $node[3] + $obj[3] ;set g score (current node's G score + adjacent node's G score)
		$obj[2] = $obj[3] + $h ;set f = g + h score
		$data[$x][$y + 1] = $obj
		$south = 1
		$openList_Str &= $obj[0] & "_"
		_Insert_PQ($openlist, $obj)
	EndIf
	$obj = $data[$x + 1][$y]
	If $obj[5] <> "x" And _ ;east
			Not _IsInAnyList($obj[0]) Then
		If $heuristic = 1 Then
			$h = _MD($obj, $goal)
		Else
			$h = _ED($obj, $goal)
		EndIf
		$obj[1] = $node[0] ;set nodes parent to last node
		$obj[3] = $node[3] + $obj[3] ;set g score (current node's G score + adjacent node's G score)
		$obj[2] = $obj[3] + $h ;set f = g + h score
		$data[$x + 1][$y] = $obj
		$east = 1
		$openList_Str &= $obj[0] & "_"
		_Insert_PQ($openlist, $obj)
	EndIf
	$obj = $data[$x - 1][$y]
	If $obj[5] <> "x" And _ ;west
			Not _IsInAnyList($obj[0]) Then
		If $heuristic = 1 Then
			$h = _MD($obj, $goal)
		Else
			$h = _ED($obj, $goal)
		EndIf
		$obj[1] = $node[0] ;set nodes parent to last node
		$obj[3] = $node[3] + $obj[3] ;set g score (current node's G score + adjacent node's G score)
		$obj[2] = $obj[3] + $h ;set f = g + h score
		$data[$x - 1][$y] = $obj
		$west = 1
		$openList_Str &= $obj[0] & "_"
		_Insert_PQ($openlist, $obj)
	EndIf
	;diagonals moves
	If $allow_diagonals_Boolean Then ;if GUI checkbox is checked, then check other 4 directions
		If $north + $east = 2 Then ;Not allowed to cut around corners, not realistic
			$obj = $data[$x + 1][$y - 1]
			If $obj[5] <> "x" And _ ;northeast
					Not _IsInAnyList($obj[0]) Then
				If $heuristic = 1 Then
					$h = _MD($obj, $goal)
				Else
					$h = _ED($obj, $goal)
				EndIf
				$obj[1] = $node[0] ;set nodes parent to last node
				$obj[3] = $node[3] + (Sqrt(2) * $obj[3]) ;set g score (current node's G score + adjacent node's G score* Sqrt(2))
				$obj[2] = $obj[3] + $h ;set f = g + h score
				$data[$x + 1][$y - 1] = $obj
				$openList_Str &= $obj[0] & "_"
				_Insert_PQ($openlist, $obj)
			EndIf
		EndIf
		If $north + $west = 2 Then
			$obj = $data[$x - 1][$y - 1]
			If $obj[5] <> "x" And _ ;north west
					Not _IsInAnyList($obj[0]) Then
				If $heuristic = 1 Then
					$h = _MD($obj, $goal)
				Else
					$h = _ED($obj, $goal)
				EndIf
				$obj[1] = $node[0] ;set nodes parent to last node
				$obj[3] = $node[3] + (Sqrt(2) * $obj[3]) ;set g score (current node's G score + adjacent node's G score* Sqrt(2))
				$obj[2] = $obj[3] + $h ;set f = g + h score
				$data[$x - 1][$y - 1] = $obj
				$openList_Str &= $obj[0] & "_"
				_Insert_PQ($openlist, $obj)
			EndIf
		EndIf
		If $south + $east = 2 Then
			$obj = $data[$x + 1][$y + 1]
			If $obj[5] <> "x" And _ ;southeast
					Not _IsInAnyList($obj[0]) Then
				If $heuristic = 1 Then
					$h = _MD($obj, $goal)
				Else
					$h = _ED($obj, $goal)
				EndIf
				$obj[1] = $node[0] ;set nodes parent to last node
				$obj[3] = $node[3] + (Sqrt(2) * $obj[3]) ;set g score (current node's G score + adjacent node's G score)
				$obj[2] = $obj[3] + $h ;set f = g + h score
				$data[$x + 1][$y + 1] = $obj
				$openList_Str &= $obj[0] & "_"
				_Insert_PQ($openlist, $obj)
			EndIf
		EndIf
		If $south + $west = 2 Then
			$obj = $data[$x - 1][$y + 1]
			If $obj[5] <> "x" And _ ;southwest
					Not _IsInAnyList($obj[0]) Then
				If $heuristic = 1 Then
					$h = _MD($obj, $goal)
				Else
					$h = _ED($obj, $goal)
				EndIf
				$obj[1] = $node[0] ;set nodes parent to last node
				$obj[3] = $node[3] + (Sqrt(2) * $obj[3]) ;set g score (current node's G score + adjacent node's G score)
				$obj[2] = $obj[3] + $h ;set f = g + h score
				$data[$x - 1][$y + 1] = $obj
				$openList_Str &= $obj[0] & "_"
				_Insert_PQ($openlist, $obj)
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_AddAdjacents_Openlist

;=============================================================================
; Replaces data grid with node objects
;parameters
;	graph
;	# of cols
;	# of rows
; Converts $data into a 2D array of node objects from previous $data array
; consisting of only string characters.
;=============================================================================
Func _CreateMap(ByRef $data, $x, $y) ;converts a 2D array of data to node objects
	For $i = 0 To $y - 1 ;for each row
		For $j = 0 To $x - 1 ;for each column
			If StringRegExp($data[$i][$j], "[x,s,g]") <> 1 Then ;if not a x,s,g
				$data[$i][$j] = _CreateNode($i & "," & $j, "null", 0, $data[$i][$j], 0, $data[$i][$j])
			Else
				If $data[$i][$j] = "s" Then
					$data[$i][$j] = _CreateNode($i & "," & $j, "null", 0, 0, 0, $data[$i][$j])
				Else
					$data[$i][$j] = _CreateNode($i & "," & $j, "null", 0, 1, 0, $data[$i][$j])
				EndIf
			EndIf
		Next
	Next
EndFunc   ;==>_CreateMap
;=============================================================================
; Creates a node struct object with parameters
; struct node {
;   char self_coord[8];          // Format = "x,y"
;   char parent_coord[8];        // Format = "x,y"
;   int f;                       // F = G + H
;   int g;                       // G = current cost to this node from start node
;   int h;                       // H = Heuristic cost, this node to goal node
;   char value[8];               // Type of node (ex. "s","g","x","1,2,3..n")
;   int cost;                    // Cost of node (difficulty of traveling on this)
; }
;=============================================================================
Func _CreateNode($self, $parent, $f, $g, $h, $value) ;returns struct object
	Local $node[6] = [$self, $parent, $f, $g, $h, $value]
	Return $node
EndFunc   ;==>_CreateNode
;=============================================================================
; Calculates the Euclidean distance between two nodes
; MD = SquareRoot ( (G(x) - N(x))^2 + (G(y) - N(x))^2 )
; Returns an integer
;=============================================================================
Func _ED(ByRef $node, ByRef $goal) ;returns integer
	Local $node_coord = StringSplit($node[0], ",") ;current node
	Local $goal_coord = StringSplit($goal[0], ",") ;goal node
	Return Sqrt(($goal_coord[1] - $node_coord[1]) ^ 2 + ($goal_coord[2] - $node_coord[2]) ^ 2) * $estimate
EndFunc   ;==>_ED
;=============================================================================
; A * Searching Algorithm
; Keep searching nodes until the goal is found.
; Returns: Array if path found
; Returns: 0 if no path
;=============================================================================
Func _FindPath(ByRef $map, $start_node, $goal_node) ;returns array of coords
	Local $openlist = ["empty"] ; ;start with empty open list
	Local $closedlist = ["empty"] ;start with empty closed list
	Local $current_node = $start_node ;set current node to start nodeF
	$closedList_Str &= $current_node[0] & "_"
	$openList_Str &= $current_node[0] & "_"
	_AddAdjacents_Openlist($map, $openlist, $closedlist, $current_node, $goal_node) ;add all possible adjacents to openlist
	While 1 ;while goal is not in closed list, or open list is not empty
		If UBound($openlist) = 1 Then ExitLoop ;if open list is empty then no path found
		$current_node = _GetLowest_F_Cost_Node($openlist) ;pick node with lowest F cost
		$closedList_Str &= $current_node[0] & "_"
		_AddAdjacents_Openlist($map, $openlist, $closedlist, $current_node, $goal_node) ;add all possible adjacents to openlist
		If $current_node[0] = $goal_node[0] Then ExitLoop ;if current node is goal then path is found!
	WEnd
	If _IsInClosedList($goal_node[0]) = 0 Then ;if no goal found then return 0
		Return 0 ; no path found
	Else
		Return _GetPath($map, $current_node, $start_node) ;return array of coords (x,y) in string format
	EndIf
EndFunc   ;==>_FindPath
;=============================================================================
; Checks to see if goal node exists in map
; Returns an array: [y,x]
;=============================================================================
Func _GetGoalLocation(ByRef $data, $cols, $rows)
	For $i = 0 To $cols - 1
		For $j = 0 To $rows - 1
			If $data[$i][$j] = "g" Then
				Local $pos[2] = [$j, $i]
				Return $pos
			EndIf
		Next
	Next
	Return 0 ;no starting location found
EndFunc   ;==>_GetGoalLocation
;=============================================================================
; Returns node object with the lowest F cost
; F = G + H
; Returns 0 with openlist is emtpy, there is no path
;=============================================================================
Func _GetLowest_F_Cost_Node(ByRef $openlist)
	If UBound($openlist) > 1 Then ;If open list is not empty
		Local $obj = $openlist[1] ;Pop first item in the queue
		_ArrayDelete($openlist, 1) ;remove this node from openlist
		Return $obj ;return lowest F cost node
	EndIf
	Return 0 ;openlist is empty
EndFunc   ;==>_GetLowest_F_Cost_Node
;=============================================================================
; Start from goal node and traverse each parent node until starting node is
; reached.
; Each node will have a parent node (use this to get path bot will take)
; Returns: Array of coords, first index is starting location
;=============================================================================
Func _GetPath(ByRef $data, ByRef $ending_node, ByRef $start_node)
	Local $path = [$ending_node[0]] ;start from goal node
	Local $node_coord = StringSplit($path[0], ",")
	Local $x = $node_coord[1]
	Local $y = $node_coord[2]
	Local $start = $start_node[0] ;starting nodes coord
	Local $obj = $data[$x][$y] ;current node starting from the goal
	While $obj[1] <> $start ;keep adding until reached starting node
		_Add_List($path, $y & "," & $x) ;add the parent node to the list
		$obj = $data[$x][$y] ;get node from 2D data array
		$node_coord = StringSplit($obj[1], ",")
		If $node_coord[0] = 1 Then ExitLoop
		$x = $node_coord[1]
		$y = $node_coord[2]
	WEnd
	_ArrayDelete($path, 0) ;no need to starting node
	_ArrayReverse($path) ;flip array to make starting node at index 0
	Return $path ;return path as array in "x,y" format for each item
EndFunc   ;==>_GetPath
;=============================================================================
; Checks to see if start node exists in map
; Returns an array: [y,x]
;=============================================================================
Func _GetStartingLocation(ByRef $data, $cols, $rows)
	For $i = 0 To $cols - 1
		For $j = 0 To $rows - 1
			If $data[$i][$j] = "s" Then
				Local $pos[2] = [$j, $i]
				Return $pos
			EndIf
		Next
	Next
	Return 0 ;no starting location found
EndFunc   ;==>_GetStartingLocation
;=============================================================================
; Inserts object into openlist and preserves ascending order
; This way will result in a priority queue with the lowest F cost at
; position 1 in the openlist array.
;=============================================================================
Func _Insert_PQ(ByRef $openlist, $node)
	Local $obj
	For $i = 1 To UBound($openlist) - 1
		Local $obj = $openlist[$i]
		If $node[2] < $obj Then
			_ArrayInsert($openlist, $i, $node)
			Return
		EndIf
	Next
	_Add_List($openlist, $node)
EndFunc   ;==>_Insert_PQ
;=============================================================================
; Returns true if node is in open list
; Regular expressions are used rather than searching an array list for speed.
;=============================================================================
Func _IsInAnyList(ByRef $node)
	If StringRegExp($openList_Str, "_" & $node & "_") Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_IsInAnyList
;=============================================================================
; Returns true if node is in closed list
; Search the list backwards, its faster
;=============================================================================
Func _IsInClosedList(ByRef $node)
	If StringRegExp($closedList_Str, "_" & $node & "_") Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_IsInClosedList
;=============================================================================
; Calculates the manhattan distance between two nodes
; MD = |G(x) - N(x)| + |G(y) - N(x)|
; Returns an integer
;=============================================================================
Func _MD(ByRef $node, ByRef $goal) ;returns integer
	Local $node_coord = StringSplit($node[0], ",") ;current node
	Local $goal_coord = StringSplit($goal[0], ",") ;goal node
	Return (Abs($goal_coord[1] - $node_coord[1]) + Abs($goal_coord[2] - $node_coord[2])) * $estimate
EndFunc   ;==>_MD
;=====================================================================================================================
;check whole graph for allies to set as source nodes
;parameters
;	source array
;=====================================================================================================================
Func allyCheck($sR)
	Local $x2
	Local $y2
	Local $copy = $sR
	Local $srCount = 0
	For $j = 0 To 7 ;for each row
		For $k = 0 To 5 ;for each col
			Local $temp = _ImageSearchArea("friendly3.png", 1, $gridX[$k] - 40, $gridY[$j] - 40, $gridX[$k] + 40, $gridY[$j] + 40, $x2, $y2, 80)
			If $temp = 1 Then
				;ToolTip("found")
				;MouseMove($x2, $y2, 30)
				$copy[$srCount][0] = $k ;set node x axis
				$copy[$srCount][1] = $j ;set y axis
				$srCount = $srCount + 1
			EndIf
			If $srCount > 5 Then ExitLoop (2) ;all nodes accounted for
		Next
	Next
	Return $copy
EndFunc   ;==>allyCheck
;============================================================================
; print sink nodes to text file
;============================================================================
Func debugSinkNodes($s)
	FileWriteLine("debug.txt", "head, tail, length, row")
	For $i = 0 To 7
		For $j = 0 To 3
			FileWrite("debug.txt", $sinkNodes[$i][$j])
			FileWrite("debug.txt", ",")
		Next
		FileWriteLine("debug.txt", "")
	Next
EndFunc   ;==>debugSinkNodes
;=====================================================================================================================
;get head nodes
; mode: 0 = row, 1 = col
;parameters
;	array of nodes
;	number of nodes to get
;	mode
;return head nodes of each group n of enemies
;=====================================================================================================================
Func getHeads($nodes, $n, $mode)
	Local $result[$n][2]
	If $mode = 0 Then
		For $i = 0 To $n - 1
			$result[$i][0] = $nodes[$i][0]
			$result[$i][1] = $nodes[$i][3]
			;FileWriteLine("debug.txt", "heads")
			;FileWrite("debug.txt", $result[$i][0])
			;FileWrite("debug.txt", ",")
			;FileWrite("debug.txt", $result[$i][1])
			;FileWriteLine("debug.txt", "")
		Next
	Else
		For $i = 0 To $n - 1
			$result[$i][0] = $nodes[$i][3]
			$result[$i][1] = $nodes[$i][0]
			;FileWriteLine("debug.txt", "heads")
			;FileWrite("debug.txt", $result[$i][0])
			;FileWrite("debug.txt", ",")
			;FileWrite("debug.txt", $result[$i][1])
			;FileWriteLine("debug.txt", "")
		Next
	EndIf
	Return $result
EndFunc   ;==>getHeads
;=====================================================================================================================
;get length of enemy strings
;parameters
;nodes
;number of strings
;=====================================================================================================================
Func getLength($sequence, $number)
	Local $lengths[$number]
	For $i = 0 To $number - 1
		$lengths[$i] = $sequence[$i][2]
	Next
	Return $lengths
EndFunc   ;==>getLength
;=====================================================================================================================
; get path from source to sink
;parameters
;	graph
;	source node[2]
;	sink node[2]
;returns path in array
;=====================================================================================================================
Func getPath($g, $source, $sink)
	$closedList_Str = "_"
	$openList_Str = "_"
	Local $tempG = setSource($g, $source[0], $source[1])
	$tempG = setSink($tempG, $sink[0], $sink[1])
	;FileWriteLine("debug.txt", "src, sink set")
	;graphPrint($tempG)
	Local $g2 = layerGraph($tempG, 6, 8)
	_CreateMap($g2, 10, 8)
	Dim $g3 = _FindPath($g2, $g2[$source[0] + 1][$source[1] + 1], $g2[$sink[0] + 1][$sink[1] + 1])
	Return $g3
EndFunc   ;==>getPath
;=====================================================================================================================
;get position of mouse
;=====================================================================================================================
Func getPos($message)
	While (1)
		ToolTip($message)
		Sleep(50)
		If _IsPressed("27") Then ExitLoop
	WEnd
	Local $result = MouseGetPos()
	Return $result
EndFunc   ;==>getPos
;=====================================================================================================================
;get tail nodes
;mode 0 = row, 1 = col
;parameters
;	array of nodes
;	number of nodes to get
;	mode
;return tail nodes of each group n of enemies
;=====================================================================================================================
Func getTails($nodes, $n, $mode)
	Local $result[$n][2]
	If $mode = 0 Then
		For $i = 0 To $n - 1
			$result[$i][0] = $nodes[$i][1]
			$result[$i][1] = $nodes[$i][3]
			;FileWriteLine("debug.txt", "tails")
			;FileWrite("debug.txt", $result[$i][0])
			;FileWrite("debug.txt", ",")
			;FileWrite("debug.txt", $result[$i][1])
			;FileWriteLine("debug.txt", "")
		Next
	Else
		For $i = 0 To $n - 1
			$result[$i][0] = $nodes[$i][3]
			$result[$i][1] = $nodes[$i][1]
			;FileWriteLine("debug.txt", "heads")
			;FileWrite("debug.txt", $result[$i][0])
			;FileWrite("debug.txt", ",")
			;FileWrite("debug.txt", $result[$i][1])
			;FileWriteLine("debug.txt", "")
		Next
	EndIf
	Return $result
EndFunc   ;==>getTails
;=====================================================================================================================
;print graph to debug.txt
;=====================================================================================================================
Func graphPrint($graph)
	For $i = 0 To 7
		For $j = 0 To 5
			FileWrite("debug.txt", $graph[$j][7 - $i])
		Next
		FileWriteLine("debug.txt", "")
	Next
	FileWriteLine("debug.txt", "")
EndFunc   ;==>graphPrint
;=====================================================================================================================
;add a layer of walls around graph
;parameters
;	graph
;	# of rows
;	# of columns
;return graph
;=====================================================================================================================
Func layerGraph($g, $x, $y)
	Local $g2[$x + 2][$y + 2] ;create layer
	For $i = 0 To $x + 1
		For $j = 0 To $y + 1
			$g2[$i][$j] = "x"
		Next
	Next
	For $i = 0 To $x - 1 ;enter graph
		For $j = 0 To $y - 1
			$g2[$i + 1][$j + 1] = $g[$i][$j]
		Next
	Next
	;FileWriteLine("debug.txt", "g2")
	;for $i = 0 to $y + 1
	;for $j = 0 to $x + 1
	;FileWrite("debug.txt",$g2[$j][$y + 1 - $i])
	;Next
	;FileWriteLine("debug.txt","")
	;Next
	;FileWriteLine("debug.txt","")
	Return $g2
EndFunc   ;==>layerGraph
;=====================================================================================================================
;find/return max
;=====================================================================================================================
Func max($x, $y)
	If ($x > $y) Then
		Return $x
	Else
		Return $y
	EndIf
EndFunc   ;==>max
;=====================================================================================================================
; move source along path to its sink
;parameters
;	path
;	source nodes
;	index of starting node
;=====================================================================================================================
Func movePiece($path, ByRef $sArray, $piece)
	Local $pathRow = UBound($path, $UBOUND_ROWS) ; Total number of rows
	Local $source = popCol($sArray, $piece, 2) ;get source node
	;fileWriteLine("debug.txt", "rows, cols")
	;fileWriteLine("debug.txt", $pathRow)
	;fileWriteLine("debug.txt", $pathCol)
	MouseMove($gridX[$source[0]], $gridY[$source[1]], 1) ;move mouse to source
	MouseDown("left")
	Sleep(500)
	For $j = 0 To $pathRow - 1
		Local $pS = StringSplit($path[$j], ",") ;get step j from path
		;fileWriteLine("debug.txt", $pS[1])
		;fileWriteLine("debug.txt", $pS[2])
		MouseMove($gridX[$pS[2] - 1], $gridY[$pS[1] - 1], 1)
		Sleep(20)
		;$sArray[$piece][0] = $pS[2] - 1
		;$sArray[$piece][1] = $pS[1] - 1
	Next
	MouseUp("left")
	Sleep(500)
EndFunc   ;==>movePiece
;=====================================================================================================================
;extract column of n length from array
;parameters
;array
;index of column to pop
;length of column
;return in n length array
;=====================================================================================================================
Func popCol($ar, $Col, $ColLength)
	Local $t[$ColLength]
	For $i = 0 To $ColLength - 1
		$t[$i] = $ar[$Col][$i]
	Next
	;fileWriteLine("debug.txt", "popcol")
	;for $i = 0 to 1
	;fileWriteLine("debug.txt", $t[$i])
	;Next
	Return $t
EndFunc   ;==>popCol
;=====================================================================================================================
;extract row of n length from array
;parameters
;	array
;	index of row to pop
;	length of row
;return in n length array
;=====================================================================================================================
Func popRow($ar, $Row, $RowLength)
	Local $t[$RowLength]
	For $i = 0 To $RowLength - 1
		$t[$i] = $ar[$i][$Row]
	Next
	;fileWriteLine("debug.txt", "poprow")
	;for $i = 0 to 1
	;fileWriteLine("debug.txt", $t[$i])
	;Next
	Return $t
EndFunc   ;==>popRow
;=====================================================================================================================
;blindly move characters
;=====================================================================================================================
Func scramble()
	MouseMove($gridX[0], $gridY[0], 4)
	Sleep(500)
	MouseDown("left")
	MouseMove($gridX[0], $gridY[7], 50)
	MouseMove($gridX[1], $gridY[7], 50) ;left 1
	MouseMove($gridX[1], $gridY[0], 50)
	MouseMove($gridX[2], $gridY[0], 50)
	MouseMove($gridX[2], $gridY[7], 50) ;left 2
	MouseMove($gridX[3], $gridY[7], 50)
	MouseMove($gridX[3], $gridY[0], 50) ;up 1
	MouseMove($gridX[4], $gridY[7], 50)
	MouseMove($gridX[5], $gridY[7], 50)
	MouseMove($gridX[5], $gridY[0], 50)
	MouseUp("left")
	Sleep(2000)
EndFunc   ;==>scramble
;=====================================================================================================================
;scroll phone down
;=====================================================================================================================
Func scrollDown()
	MouseMove($homeX, $homeY - 750, 10)
	Sleep(250)
	MouseDown("left")
	Sleep(250)
	MouseMove($homeX, $homeY - 250, 10)
	MouseUp("left")
	Sleep(150)
EndFunc   ;==>scrollDown
;=====================================================================================================================
;scroll phone up
;=====================================================================================================================
Func scrollUp()
	MouseMove($homeX, $homeY - 250, 10)
	Sleep(250)
	MouseDown("left")
	Sleep(250)
	MouseMove($homeX, $homeY - 750, 10)
	MouseUp("left")
	Sleep(150)
EndFunc   ;==>scrollUp
;=====================================================================================================================
;get head and sink nodes for longest string of enemies in each row
;return array [8][4](head, tail, length, row)
;=====================================================================================================================
Func sequenceMap($mapX)
	Local $s[8][4]
	Local $tempRow[6]
	For $i = 0 To 7 ;for each row
		For $j = 0 To 5 ;for each column
			$tempRow[$j] = $mapX[$j][$i] ;copy row to temp string
		Next
		Local $temp = sequenceString($tempRow, 6)
		$s[$i][0] = $temp[0] ;head
		$s[$i][1] = $temp[1] ;tail
		$s[$i][2] = $temp[2] + 1 ;length , add 1 to prioritize rows over columns.
		$s[$i][3] = $i ;row
	Next
	_ArraySort($s, 1, 0, 0, 2) ;sort by length
	Return $s
EndFunc   ;==>sequenceMap
;=====================================================================================================================
;get head and sink nodes for longest string of enemies in each column
;return array [6][4](headx, tail, length, row)
;=====================================================================================================================
Func sequenceMapCol($mapX)
	Local $s[6][4]
	Local $tempCol[8]
	For $i = 0 To 5
		For $j = 0 To 7
			$tempCol[$j] = $mapX[$i][$j]
		Next
		$temp = sequenceString($tempCol, 8)
		$s[$i][0] = $temp[0] ;head
		$s[$i][1] = $temp[1] ;tail
		$s[$i][2] = $temp[2] ;length
		$s[$i][3] = $i ;col
	Next
	_ArraySort($s, 1, 0, 0, 2)
	Return $s
EndFunc   ;==>sequenceMapCol
;=====================================================================================================================
;find largest sequence of enemies
;paramters
;	string
;	length of string
;return (head, tail, length)
;=====================================================================================================================
Func sequenceString($str, $strLen)
	;Tooltip("sequencing string")
	Local $result[3]
	Local $maxLength = 0
	Local $length = 0
	Local $temp = 0
	For $i = 0 To $strLen - 1
		If $str[$i] = "0" Then
			$length = $i - $temp ;get length of head and tail
			If $length > $maxLength Then
				$maxLength = $length
				$result[0] = $i ;head
				$result[1] = $temp ;tail
				$result[2] = $maxLength ;length
			EndIf
			$temp = $i ;save last location
		EndIf
	Next
	If ($result[0] = $strLen - 1) Then ;if head at edge of map, swap head/tail to avoid stuck pieces
		Local $temp2 = $result[0]
		$result[0] = $result[1]
		$result[1] = $temp2
	EndIf
	Return $result
EndFunc   ;==>sequenceString
;=====================================================================================================================
;set allies on graph
;return graph
;=====================================================================================================================
Func SetAllies($graph)
	Local $x
	Local $y
	For $i = 1 To 7 ;for each row
		For $j = 0 To 5 ;for each column
			Local $temp = _ImageSearchArea("friendly.png", 1, $gridX[$j] - 40, $gridY[$i] - 40, $gridX[$j] + 40, $gridY[$i] + 40, $x, $y, 35) ;search each node
			;MouseMove($x, $y, 10)
			If $temp = 1 Then
				$graph[$j][$i] = "0" ;update graph
			EndIf
		Next
	Next
	Return $graph
EndFunc   ;==>SetAllies
;=====================================================================================================================
;set block
;parameters
;	graph
;	x coordinate
;	y coordinate
;return graph
;=====================================================================================================================
Func setBlock($g, $x, $y)
	$g[$x][$y] = "x"
	;graphPrint($g)
	Return $g
EndFunc   ;==>setBlock
;=====================================================================================================================
;set enemies on graph
;return graph
;=====================================================================================================================
Func setEnemies($graph)
	Local $x
	Local $y
	Local $enemies = _FileListToArray(@ScriptDir & "\" & $mapToRun) ;get enemy images
	Local $enemyCount = 0
	Local $degree = 0 ;base tolerance
	While ($enemyCount = 0)
		For $i = 0 To 7 ;for each row
			For $j = 0 To 5 ;for each column
				For $k = 1 To $enemies[0]
					Local $temp = _ImageSearchArea(@ScriptDir & "\" & $mapToRun & "\" & $enemies[$k], 1, $gridX[$j] - 40, $gridY[$i] - 40, $gridX[$j] + 40, $gridY[$i] + 40, $x, $y, $degree) ;search for image $k
					If $temp = 1 Then
						;MouseMove($x, $y, 10)
						$graph[$j][$i] = "x" ;update graph
						$enemyCount = $enemyCount + 1
						ExitLoop
					EndIf
				Next
			Next
		Next
		$degree = $degree + 5 ;increase tolerance if too low
	WEnd
	;graphPrint($graph)
	Return $graph
EndFunc   ;==>setEnemies
;=====================================================================================================================
;set sink node
;parameters
;	graph
;	x coordinate
;	y coordinate
;return graph
;=====================================================================================================================
Func setSink($g, $x, $y)
	$g[$x][$y] = "g"
	;graphPrint($g)
	Return $g
EndFunc   ;==>setSink
;=====================================================================================================================
;set source node
;parameters
;	graph
;	x coordinate
;	y coordinate
;return graph
;=====================================================================================================================
Func setSource($g, $x, $y)
	$g[$x][$y] = "s"
	;graphPrint($g)
	Return $g
EndFunc   ;==>setSource
;=====================================================================================================================
;set runners on graph
;return graph
;=====================================================================================================================
Func setTraps($graph, $value)
	Local $x
	Local $y
	Local $traps = _FileListToArray(@ScriptDir & "\" & $mapToRun & "\traps")
	If @error <> 4 Then
		For $i = 1 To 7 ;for each row
			For $j = 0 To 5 ;for each column
				For $k = 1 To $traps[0]
					Local $temp = _ImageSearchArea(@ScriptDir & "\" & $mapToRun & "\traps\" & $traps[$k], 1, $gridX[$j] - 40, $gridY[$i] - 40, $gridX[$j] + 40, $gridY[$i] + 40, $x, $y, 40)
					;MouseMove($x, $y, 10)
					If $temp = 1 Then
						$graph[$j][$i] = $value ;update graph
					EndIf
				Next
			Next
		Next
	EndIf
	Return $graph
EndFunc   ;==>setTraps
;=====================================================================================================================
;use mover piece to shift source along path to sink
;input: path from shifted piece to its source
;source array
;index of mover source node
;graph
;index of shifted source node
;index of mover piece's sink
;=====================================================================================================================
Func shiftPiece($path, ByRef $sArray, $piece, $graph, $pathSource, $moverSink)
	Local $pathRow = UBound($path, $UBOUND_ROWS) ;get rows
	If $pathRow = 0 Then
		scramble()
		Return
	EndIf
	Local $mover = popCol($sArray, $piece, 2) ;get mover location
	Local $shift = popCol($sArray, $pathSource, 2) ;get shift location
	Local $temp = StringSplit($path[0], ",") ;get first step on path
	Local $temPath
	Local $endFlag = 0 ;to detect when piece is shifted to sink
	Local $copy[6][8]
	$temp[0] = $temp[2] - 1
	$temp[1] = $temp[1] - 1
	$graph = setBlock($graph, $shift[0], $shift[1]) ;set shift location as x
	$bridge = getPath($graph, $mover, $temp) ;bridge mover and path
	Local $bridgeRow = UBound($bridge, $UBOUND_ROWS)
	MouseMove($gridX[$mover[0]], $gridY[$mover[1]], 1)
	MouseDown("left")
	Sleep(200)

	For $i = 0 To $bridgeRow - 1 ;move mover piece onto path
		Local $tB = StringSplit($bridge[$i], ",")
		MouseMove($gridX[$tB[2] - 1], $gridY[$tB[1] - 1], 1)
		Sleep(20)
	Next

	MouseMove($gridX[$shift[0]], $gridY[$shift[1]], 1) ;swap mover and shift
	Sleep(20)
	$copy = setBlock($graph, $temp[0], $temp[1])
	$mover[0] = $shift[0] ;update mover location
	$mover[1] = $shift[1]

	For $j = 0 To $pathRow - 1 ;Shift piece to sink using mover
		;for $j, mover = j - 1, shift = j
		Local $pS = StringSplit($path[$j], ",")
		If $j < $pathRow - 1 Then
			Local $nextStep = StringSplit($path[$j + 1], ",")
		Else
			Local $nextStep = StringSplit($path[$pathRow - 1], ",")
			$endFlag = 1
		EndIf
		$nextStep[0] = $nextStep[2] - 1
		$nextStep[1] = $nextStep[1] - 1

		$temPath = getPath($copy, $mover, $nextStep)
		;fileWriteLine("debug.txt", $pS[1])
		;fileWriteLine("debug.txt", $pS[2])
		Local $tempRow = UBound($temPath, $UBOUND_ROWS) ;get rows
		For $k = 0 To $tempRow - 1 ;put mover at next position on path
			Local $temp0 = StringSplit($temPath[$k], ",")
			MouseMove($gridX[$temp0[2] - 1], $gridY[$temp0[1] - 1], 1)
			Sleep(20)
			$copy = setBlock($graph, $temp0[2] - 1, $temp0[1] - 1)
		Next
		If $endFlag = 1 Then ExitLoop ;dont swap pos if at end of path
		MouseMove($gridX[$pS[2] - 1], $gridY[$pS[1] - 1], 2) ;swap mover and shift
		Sleep(20)
		$mover[0] = $pS[2] - 1 ;update mover location
		$mover[1] = $pS[1] - 1
	Next
	$temp = StringSplit($path[$pathRow - 1], ",")
	$temp[0] = $temp[2] - 1
	$temp[1] = $temp[1] - 1
	$graph = setBlock($graph, $temp[0], $temp[1])
	$moverSinkPath = getPath($graph, $mover, $moverSink)
	Local $moverSinkRow = UBound($moverSinkPath, $UBOUND_ROWS)

	For $i = 0 To $moverSinkRow - 1 ;move mover piece to its sink
		Local $temp1 = StringSplit($moverSinkPath[$i], ",")
		MouseMove($gridX[$temp1[2] - 1], $gridY[$temp1[1] - 1], 1)
		Sleep(20)
		$sArray[$piece][0] = $temp1[2] - 1
		$sArray[$piece][1] = $temp1[1] - 1
	Next

	MouseUp("left")
EndFunc   ;==>shiftPiece


Func Stop() ;stop
	MsgBox(0, "Notice", "Stopping")
	Exit ;same
EndFunc   ;==>Stop
;=====================================================================================================================
;pause bot
;return to last postion on resume
;=====================================================================================================================
Func TogglePause()
	$Paused = Not $Paused
	If ($Paused = 1) Then
		$mPos = MouseGetPos()
	Else
		ToolTip("running", $pX + 255, $pY - 980)
		MouseMove($mPos[0], $mPos[1], 10)
	EndIf
	While $Paused
		ToolTip("paused", $pX + 255, $pY - 980)
		Sleep(100)
	WEnd
EndFunc   ;==>TogglePause
;=====================================================================================================================
;get image and save at directory
;=====================================================================================================================
Func trainImage()
	Local $mapName = InputBox("Notice", "Enter name of Map", "")
	DirCreate(@ScriptDir & "\" & $mapName)
	Local $name = InputBox("Notice", "Enter name of picture", "")
	$p1 = getPos("press right arrow on top left of image to capture")
	$image = _ScreenCapture_Capture(@ScriptDir & "\" & $mapName & "\" & $name & ".png", $p1[0], $p1[1], $p1[0] + 10, $p1[1] + 10)
	_ScreenCapture_SaveImage(@ScriptDir & "\" & $mapName & "\" & $name & ".png", $image)
EndFunc   ;==>trainImage

