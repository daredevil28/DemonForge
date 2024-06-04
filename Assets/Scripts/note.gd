class_name Note extends InternalNote

var interval : int :
	#If we change the interval also change the label text
	set(value):
		interval = value
		$Label.text = str(value)
