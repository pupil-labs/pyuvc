'''
(*)~----------------------------------------------------------------------------------
 Pupil - eye tracking platform
 Copyright (C) 2012-2015  Pupil Labs

 Distributed under the terms of the CC BY-NC-SA License.
 License details are in the file license.txt, distributed as part of this software.
----------------------------------------------------------------------------------~(*)
'''

standard_ctrl_units = [
{
'display_name': 'Auto Exposure Mode',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_AE_MODE_CONTROL ,
'bit_mask': 1<<1,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 1,
'max_val': 8,
'step':None,
'def_val':None,
'd_type': {'manual mode':1, 'auto mode': 2, 'shutter priority mode': 4, 'aperture priority mode':8 },
'doc': ''
}
,
{
'display_name': 'Auto Exposure Priority',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_AE_PRIORITY_CONTROL ,
'bit_mask': 1<<2,
'offset': 0,
'data_len': 1,
'buffer_len': 1,
'min_val': 0,
'max_val': 1,
'step':1,
'def_val':0,
'd_type': bool,
'doc':'0: frame rate must remain constant; 1: frame rate may be varied for AE purposes'
}
,
{
'display_name': 'Absolute Exposure Time',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_EXPOSURE_TIME_ABSOLUTE_CONTROL ,
'bit_mask': 1<<3,
'offset': 0 ,
'data_len': 4 ,
'buffer_len': 4,
'min_val': None,
'max_val': 500, #usually None but we overwrite,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'The `time` parameter should be provided in units of 0.0001 seconds (e.g., use the value 100 \
for a 10ms exposure period). Auto exposure should be set to `manual` or `shutter_priority`\
before attempting to change this setting.'
}
,
{
'display_name': 'Auto Focus',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_FOCUS_AUTO_CONTROL ,
'bit_mask': 1<<17,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 1,
'step':1,
'def_val':None,
'd_type': bool,
'doc': 'Enable the Auto Focus'
}
,
{
'display_name': 'Absolute Focus',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_FOCUS_ABSOLUTE_CONTROL ,
'bit_mask': 1 << 5,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'Set Absolute Focus'
}
,
{
'display_name': 'Absolute Iris ',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_IRIS_ABSOLUTE_CONTROL ,
'bit_mask':1 << 7,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'Set Absolute Iris Control.'
}
,
{
'display_name': 'Scanning Mode ',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_SCANNING_MODE_CONTROL ,
'bit_mask':1 << 0,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 1,
'step':1,
'def_val':0,#I have assumed the defaul value as 0 becuase nothing was specified
'd_type': {'interlaced':0,'progessive':1},
'doc': 'Set the scanning mode'
}
#,
#{
#'display_name': 'Exposure(time) relative',
#'unit': 'input_terminal',
#'control_id': uvc.UVC_CT_EXPOSURE_TIME_RELATIVE_CONTROL ,
#'bit_mask': 1 << 4,
#'offset': 0 ,
#'data_len': 1 ,
#'buffer_len': 1,
#'min_val': 0,#assumed
#'max_val': 255,#assumed
#'step':1,
#'def_val':0,
#'d_type': {'increment mode':1,'decrement mode':255},
#'doc': 'The setting for Exposure time relatvie control.'
#}
#,
#{
#'display_name': 'Focus relative',
#'unit': 'input_terminal',
#'control_id': uvc.UVC_CT_FOCUS_RELATIVE_CONTROL ,
#'bit_mask': 1 << 6,
#'offset':1 ,
#'data_len': 1 ,
#'buffer_len': 2,
#'min_val': None,
#'max_val': None,
#'step':None,
#'def_val':None,
#'d_type': {'Stop':0,'Focus Near direction':1,'Focus Infinite Direction':255},#Please check this field
#'doc': 'The setting for Relative focus.'
#}
#,
#{
#'display_name': 'Iris relative control',
#'unit': 'input_terminal',
#'control_id': uvc.UVC_CT_IRIS_RELATIVE_CONTROL ,
#'bit_mask': 1 << 8,
#'offset': 0,
#'data_len': 1,
#'buffer_len': 1,
#'min_val': 0,
#'max_val': 255, #Assumption
#'step':1,
#'def_val':0,
#'d_type': {'Default':0, 'Iris is opened my one step':1, 'Iris is closed by one step':255},
#'doc':'A step value of 1 indicates that the iris is opened 1 step further. A value of 0xFF indicates that the iris is closed 1 step further.'
#}
,
{
'display_name': 'Zoom absolute control',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_ZOOM_ABSOLUTE_CONTROL ,
'bit_mask': 1 << 9,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'The Zoom (Absolute) Control.'
}
,
{
'display_name': 'Pan control',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_PANTILT_ABSOLUTE_CONTROL ,
'bit_mask': 1 << 11,
'offset': 0 ,
'data_len': 4 ,
'buffer_len': 8,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'Pan (Absolute) Control.'
}
,
{
'display_name': 'Tilt control',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_PANTILT_ABSOLUTE_CONTROL ,
'bit_mask': 1 << 11,
'offset': 4 ,
'data_len': 4 ,
'buffer_len': 8,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'Tilt (Absolute) Control.'
}
,
{
'display_name': 'Roll absolute control',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_ROLL_ABSOLUTE_CONTROL ,
'bit_mask': 1 << 13,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'The Roll (Absolute) Control is used to specify the roll setting in degrees. Values range from –180 to +180, or a subset thereof.'
}
,
{
'display_name': 'Privacy Shutter control',
'unit': 'input_terminal',
'control_id': uvc.UVC_CT_PRIVACY_CONTROL ,
'bit_mask': 1 << 18,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 1,
'step':1,
'def_val':0,#Assumption
'd_type': bool,
'doc': 'A value of 0 indicates that the camera sensor is able to capture video images, and a value of 1 indicates that the camera sensor is prevented from capturing video images.'
}
,
{
'display_name': 'Backlight Compensation',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_BACKLIGHT_COMPENSATION_CONTROL ,
'bit_mask': 1 << 8,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'The Backlight Compensation Control is used to specify the backlight compensation.'
}
,
{
'display_name': 'Brightness',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_BRIGHTNESS_CONTROL ,
'bit_mask': 1 << 0,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the brightness.'
}
,
{
'display_name': 'Contrast',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_CONTRAST_CONTROL ,
'bit_mask': 1 << 1,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the contrast value.'
}
,
{
'display_name': 'Gain',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_GAIN_CONTROL ,
'bit_mask':1 << 9,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the gain setting.'
}
,
{
'display_name': 'Power Line frequency',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_POWER_LINE_FREQUENCY_CONTROL ,
'bit_mask':1 << 10,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 2,
'step':1,
'def_val':None,
'd_type': {'Disabled':0,'50Hz':1,'60Hz':2},
'doc': 'This control allows the host software to specify the local power line frequency,for the implementing anti-flicker processing.'
}
,
{
'display_name': 'Hue',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_HUE_CONTROL ,
'bit_mask':1 << 2,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None, #in the description of the control it is said that the default value must be zero but the mandatory request says GET_DEF hence I wrote None
'd_type': int,
'doc': 'This is used to specify the hue setting.'
}
,
{
'display_name': 'Saturation',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_SATURATION_CONTROL ,
'bit_mask':1 << 3,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the saturation setting.'
}
,
{
'display_name': 'Sharpness',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_SHARPNESS_CONTROL ,
'bit_mask':1 << 4,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the sharpness setting.'
}
,
{
'display_name': 'Gamma',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_GAMMA_CONTROL ,
'bit_mask':1 << 5,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the gamma setting.'
}
,
{
'display_name': 'White Balance temperature',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_WHITE_BALANCE_TEMPERATURE_CONTROL ,
'bit_mask': 1 << 6,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the white balance setting as a color temperature in degrees Kelvin.'
}
,
{
'display_name': 'White Balance temperature blue',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_WHITE_BALANCE_COMPONENT_CONTROL ,
'bit_mask': 1 << 7,
'offset': 0 ,
'data_len': 2 ,
'buffer_len': 4,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'Set the blue component for white balance.'
}
,{
'display_name': 'White Balance temperature red',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_WHITE_BALANCE_COMPONENT_CONTROL ,
'bit_mask': 1 << 7,
'offset': 2 ,
'data_len': 2 ,
'buffer_len': 4,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'Set the red component for white balance.'
}
,
{
'display_name': 'White Balance temperature,Auto',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL ,
'bit_mask': 1 << 12,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 1,
'step':1,
'def_val':None,
'd_type': int,
'doc': 'The White Balance Temperature Auto Control setting determines whether the device will provide automatic adjustment of the related control.1 indicates automatic adjustment is enabled'
}
,
{
'display_name': 'White Balance component,Auto',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL ,
'bit_mask': 1 << 13,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 1,
'step':1,
'def_val':None,
'd_type': int,
'doc': 'The White Balance Component Auto Control setting determines whether the device will provide automatic adjustment of the related control.'
}
,
{
'display_name': 'Digital Multiplier',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_DIGITAL_MULTIPLIER_CONTROL,
'bit_mask': 1 << 14,
'offset': 0 ,
'data_len': 2,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify the amount of Digital Zoom applied to the optical image.'
}
,
{
'display_name': 'Digital Multiplier limit control',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL,
'bit_mask': 1 << 15,
'offset': 0 ,
'data_len': 2,
'buffer_len': 2,
'min_val': None,
'max_val': None,
'step':None,
'def_val':None,
'd_type': int,
'doc': 'This is used to specify an upper limit for the amount of Digital Zoom applied to the optical image.'
}
,
{
'display_name': 'Analog video standard',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_ANALOG_VIDEO_STANDARD_CONTROL,
'bit_mask': 1 << 15,
'offset': 0 ,
'data_len': 1,
'buffer_len': 1,
'min_val': 0,
'max_val': 255,
'step':1,
'def_val':0,
'd_type':  {'NTSC – 525/60':1, 'PAL – 625/50': 2, 'SECAM – 625/50': 3, 'NTSC – 625/50':4,'PAL – 525/60':5},
'doc': 'This is used to report the current Video Standard of the stream captured by the Processing Unit.'
}
,
{
'display_name': 'Analog lock status control',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_ANALOG_LOCK_STATUS_CONTROL,
'bit_mask': 1 << 17,
'offset': 0 ,
'data_len': 1,
'buffer_len': 1,
'min_val': 0,
'max_val': 255,
'step':1,
'def_val':0,#assumed
'd_type': {'Video decoder is locked':0,'Video decoder is not locked':1},
'doc': 'This is used to report whether the video decoder has achieved horizontal lock of the analog input signal.'
}
,
{
'display_name': 'Hue Auto control',
'unit': 'processing_unit',
'control_id': uvc.UVC_PU_HUE_AUTO_CONTROL ,
'bit_mask':1 << 11,
'offset': 0 ,
'data_len': 1 ,
'buffer_len': 1,
'min_val': 0,
'max_val': 1, #Assumed
'step':1, #assumed
'def_val':None,
'd_type': int,
'doc': 'The Hue Auto Control setting determines whether the device will provide automatic adjustment of the related control.'
}
]



cdef class Control:
    cdef uvc.uvc_device_handle_t *devh
    cdef public str display_name,doc,unit
    cdef int unit_id,control_id,offset,data_len,bit_mask,_value
    cdef readonly int min_val,max_val,step,def_val,buffer_len,info_bit_mask
    cdef public object d_type

    def __cinit__(self,
                    Capture cap,
                    unit_id,
                    display_name,
                    unit,
                    control_id,
                    offset,
                    data_len,
                    bit_mask,
                    d_type,
                    doc=None,
                    buffer_len=None,
                    min_val=None,
                    max_val=None,
                    step=None,
                    def_val=None):
        pass

    def __init__(self,
                    Capture cap,
                    unit_id,
                    display_name,
                    unit,
                    control_id,
                    offset,
                    data_len,
                    bit_mask,
                    d_type,
                    doc=None,
                    buffer_len=None,
                    min_val=None,
                    max_val=None,
                    step=None,
                    def_val=None):

        self.devh = cap.devh
        self.display_name = display_name
        self.unit_id = unit_id
        self.unit = unit
        self.control_id = control_id
        self.offset = offset
        self.data_len = data_len
        self.bit_mask = bit_mask
        self.d_type = d_type
        self.doc = doc

        if buffer_len is None:
            self.buffer_len = uvc.uvc_get_ctrl_len(self.devh,self.unit_id, self.control_id)
            if self.buffer_len < 1:
                raise Exception("Could not get buffer Length: Error: %s"%uvc_error_codes[self.buffer_len])
        else:
            self.buffer_len = buffer_len

        self.info_bit_mask = self._uvc_get(uvc.UVC_GET_INFO)
        self._value = self._uvc_get(uvc.UVC_GET_CUR)
        self.min_val = min_val if min_val != None else self._uvc_get(uvc.UVC_GET_MIN)
        self.max_val = max_val if max_val != None else self._uvc_get(uvc.UVC_GET_MAX)
        self.step    = step    if step    != None else self._uvc_get(uvc.UVC_GET_RES)
        self.def_val = def_val if def_val != None else self._uvc_get(uvc.UVC_GET_DEF)

        if self.d_type == int and len(range(self.min_val,self.max_val+1,self.step)) == 2:
            self.d_type = bool
        #we could filter out unsupported entries but device dont always implement this correctly.
        #if type(self.d_type) == dict:
        #    possible_vals = range(self.min_val,self.max_val+1,self.step)
        #    print possible_vals
        #    filtered_entries = {}
        #    for key,val in self.d_type.iteritems():
        #        if val in possible_vals:
        #            filtered_entries[key] = val
        #    self.d_type = filtered_entries

    def __str__(self):
        return "%s"%self.display_name \
        + '\n\t value: %s'%self._value \
        + '\n\t min: %s'%self.min_val \
        + '\n\t max: %s'%self.max_val \
        + '\n\t step: %s'%self.step \
        + '\n\t default: %s'%self.def_val

    cdef _uvc_get(self, req_code):
        cdef uvc.uint8_t data[12] #could be done dynamically
        memset(data,0,12)
        cdef int ret
        ret =  uvc.uvc_get_ctrl(self.devh, self.unit_id, self.control_id,data,self.buffer_len, req_code)
        if ret > 0: #== self.buffer_len
            if self.data_len == 1:
                return data[0]
            elif self.data_len ==2:
                return uvc.SW_TO_SHORT(data + self.offset)
            else:
                return uvc.DW_TO_INT(data + self.offset)
        else:
            raise Exception("Error: %s"%uvc_error_codes[ret])

    cdef _uvc_set(self, value):
        cdef uvc.uint8_t data[12] #could be done dynamically
        memset(data,0,12)

        cdef int ret
        if self.data_len != self.buffer_len:
            #read-modify-write
            uvc.uvc_get_ctrl(self.devh, self.unit_id, self.control_id,data,self.buffer_len, uvc.UVC_GET_CUR)

        if self.data_len ==1:
            data[0] = value
        elif self.data_len == 2:
            uvc.SHORT_TO_SW(value,data+self.offset)
        else:
            uvc.INT_TO_DW(value,data+self.offset)

        ret =  uvc.uvc_set_ctrl(self.devh, self.unit_id, self.control_id,data,self.buffer_len)
        if ret <= 0: #== self.buffer_len
            raise Exception("Error: %s"%uvc_error_codes[ret])

    cpdef refresh(self):
        self._value = self._uvc_get(uvc.UVC_GET_CUR)

    property value:
        def __get__(self):
            return self._value
        def __set__(self,value):
            try:
                self._uvc_set(value)
            except:
                logger.warning("Could not set Value. '%s'."%self.display_name)
            try:
                self._value = self._uvc_get(uvc.UVC_GET_CUR)
            except:
                logger.warning("Could not get Value. Must be read disabled.")
