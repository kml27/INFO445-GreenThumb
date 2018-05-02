USE GREEN_THUMB
GO

INSERT INTO tblUnit	(UnitName, UnitAbbr)
	VALUES	('metre', 'm'),
			('centimetre', 'cm'),
			('milimetre', 'mm'),
			('square meter', 'm^2'),
			('square centimeter', 'cm^2'),
			('square milimeter', 'mm^2'),
			('gram', 'g'),
			('kilogram', 'kg'),
			('litre', 'l'),
			('centilitre', 'cl'),
			('mililitre', 'ml'),
			('potential of hydrogen', 'pH'),
			('none', 'NA')
GO

INSERT INTO tblDetailType	(DetailTypeName, DetailTypeDesc)
	VALUES	('color', 'primary color of the item'),
			('leaf size', 'how large are the leaves'),
			('stalk width', 'how wide is the stalk'),
			('leaf density', 'how dense are the leaves'),
			('weight', 'how much does it weigh'),
			('length', 'how long is it'),
			('height', 'how tall is it'),
			('width', 'how wide is it'),
			('volume', 'how much space does it take up'),
			('soil pH', 'how acidic is the soil'),
			('stalk color', 'what color is the stalk')
GO
