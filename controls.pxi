
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
'default':None,
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
'default':0,
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
'max_val': None,
'step':None,
'default':None,
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
'default':None,
'd_type': bool,
'doc': 'Enable the Auto Focus'
}
]



cdef class Control:
    cdef uvc.uvc_device_handle_t *devh
    cdef bytes display_name,doc
    cdef int unit_id,control_id,offset,data_len,bit_mask
    cdef int _value,min_val,max_val,step,default,buffer_len,info_bit_mask
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
                    default=None):
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
                    default=None):

        self.devh = cap.devh
        self.display_name = display_name
        self.unit_id = unit_id
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
        self.max_val = min_val if max_val != None else self._uvc_get(uvc.UVC_GET_MAX)
        self.step    = step    if step    != None else self._uvc_get(uvc.UVC_GET_RES)
        self.default = default if default != None else self._uvc_get(uvc.UVC_GET_DEF)

    def print_info(self):
        print self.display_name
        print '\t value: %s'%self._value
        print '\t min: %s'%self.min_val
        print '\t max: %s'%self.max_val
        print '\t step: %s'%self.step
        print '\t default: %s'%self.default

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

        if self.data_len ==1:
            data[0] = value
        elif self.data_len == 2:
            uvc.SHORT_TO_SW(value,data+self.offset)
        else:
            uvc.INT_TO_DW(value,data+self.offset)

        ret =  uvc.uvc_get_ctrl(self.devh, self.unit_id, self.control_id,data,self.data_len, uvc.UVC_SET_CUR)
        if ret != self.buffer_len:
            raise Exception("Error: %s"%uvc_error_codes[ret])


    property value:
        def __get__(self):
            return self._value
        def __set__(self,value):
            self._uvc_set(value)
            self._value = self._uvc_get(uvc.UVC_GET_CUR)
