-- VECTRIC LUA SCRIPT
require "strict"
a = 0
y = 0
xMin = 0
xMax = 1
res = 0.026
equation = ""
g_dialogHtml = [[]]
.. [[<body bgcolor="#CCCCFF">]]
	.. [[<table>]]
	.. [[<tr><td width="30%"><b>Equation</b></td><td><input id="equation" name="textfield" type="text"></td></tr>]]
	.. [[<tr><td width="30%"><b>X Minimum</b></td><td><input id="xmin" name="textfield" type="text"></td></tr>]]
	.. [[<tr><td width="30%"><b>X Maximum</b></td><td><input id="xmax" name="textfield" type="text"></td></tr>]]
	.. [[<tr><td width="30%"><b>Resolution</b></td><td><input id="res" name="textfield" type="text"></td></tr>]]
	.. [[</table>]]
	.. [[<input id="PlotEQ" class="LuaButton" name="PlotEQ" type="button" value="Plot">]]
.. [[</body>]]

function OnLuaButton_PlotEQ(dialog)
	local job = VectricJob()
	if not job.Exists then
		return true
	end
	if not UpdateOptionsFromDialog(dialog) then
		return true
	end
	PlotPoints()
	job:Refresh2DView()
	return true
end

function UpdateOptionsFromDialog(dialog)
	equation = dialog:GetTextField("equation")
	equation = equationParse(equation)
	xMin  = dialog:GetDoubleField("xMin")
	xMax  = dialog:GetDoubleField("xMax")
	res = dialog:GetDoubleField("res")
    equation = "return function(x) return " .. equation .. " end"
    return true
end

function equationParse(equation)
local eq = equation
eq = string.gsub(eq,"[math%.]-sin","math.sin")
eq = string.gsub(eq,"[math%.]-cos","math.cos")
eq = string.gsub(eq,"[math%.]-tan","math.tan")
eq = string.gsub(eq,"[math%.]-asin","math.asin")
eq = string.gsub(eq,"[math%.]-acos","math.acos")
eq = string.gsub(eq,"[math%.]-atan","math.atan")
eq = string.gsub(eq,"[math%.]-deg","math.deg")
eq = string.gsub(eq,"[math%.]-degree","math.deg")
eq = string.gsub(eq,"[math%.]-degrees","math.deg")
eq = string.gsub(eq,"[math%.]-rad","math.radians")
eq = string.gsub(eq,"[math%.]-radian","math.radians")
eq = string.gsub(eq,"[math%.]-radians","math.radians")
eq = string.gsub(eq,"[math%.]-exp","math.exp")
eq = string.gsub(eq,"[math%.]-log","math.log")
eq = string.gsub(eq,"[math%.]-log10","math.log10")
eq = string.gsub(eq,"[math%.]-pi","math.pi")
return eq
end

function main(script_path)
	local retry_dialog = true
	local job = VectricJob()
	if not job.Exists then
		DisplayMessageBox("There is no existing job open")
		return false;
	end
	job:Refresh2DView()
	local frmMain = HTML_Dialog(true, g_dialogHtml, 350, 200, "Equation Plotter")
	frmMain:AddTextField("equation", equation)
	frmMain:AddDoubleField("xMin", xMin)
	frmMain:AddDoubleField("xMax", xMax)
	frmMain:AddDoubleField("res", res)
	frmMain:ShowDialog() 
	return true
end

function findNextPt(a)
	local x1 = a
	local y1 = calcY(x1)
	local x2 = 0
	local y2 = 0
	local length = res
	local resVar = res
	local done = 0
	while done < 1 do
		x2 = x1 + resVar
		y2 = calcY(x2)	
		length = math.sqrt(math.abs(math.pow(x2-x1,2))+math.abs(math.pow(y2-y1,2)))
		if length >= res * 0.975 and length <= res*1.025 then
			done = 1
		end
		resVar = resVar * (res/length)
	end
return x2
end

function PlotPoints()
	local mydoc = VectricJob()
	local linePTs = {}
	local MyLine 
	if not mydoc.Exists then
		MessageBox("There is no existing doc loaded")
		return false;
	end
	local done = 0
	local xbound = xMax
	a = xMin
    y = calcY(a)
	local i = 0
	while done < 1 do
		linePTs[i] = Point2D(1*a,y)
		a = findNextPt(a,res)
		y = calcY(a)

		if a > xbound then
			done = 1
		end
    	i= i + 1
	end
	MyLine = Draw_Line(mydoc,linePTs)
	Refresh(mydoc,MyLine,"Sprial")
	return true
end

function calcY(xVal)
a = xVal
local func, err = load(equation)
if func then
  local ok, calc = pcall(func)
  if ok then
    y = calc(a)
  else
    print("Execution error:", calc)
  end
else
  print("Compilation error:", err)
end
return y
end

function Draw_Line(doc,XYPoints)
	local MyContour = Contour(0.0)
	local p1 = XYPoints[0]
   	MyContour:AppendPoint(p1)
	for i=1, #XYPoints do
		local p2 = XYPoints[i]
		MyContour:LineTo(p2)
	end
	return MyContour; 
end

function Refresh (doc,Contour,LayerName)
	local cad_object = CreateCadContour(Contour)
	local cur_layer = doc.LayerManager:GetActiveLayer()
	local layer = doc.LayerManager:GetLayerWithName(LayerName)
	layer:AddObject(cad_object, true)
	layer.Colour = 0 
	layer.Visible = true 
	doc.LayerManager:SetActiveLayer(cur_layer)
	doc.Selection:Add(cad_object, true, false)
	doc:Refresh2DView()
	return true
end