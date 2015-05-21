

uvc_input_terminal_id = 1
uvc_processing_unit_id = 1

standard_ctrl_units = [
{
'display_name': 'Auto Exposure Mode',
'unit': 'processing_unit',
'control_id': 0x02 ,
'offset': 0 ,
'data_len': 1 ,
'bit_mask': 1<<1,
'd_type': {'manual mode':1, 'auto mode': 2, 'shutter priority mode': 4, 'aperture priority mode':8 },
'doc': ''
}
,
{
'display_name': 'Auto Exposure Priority',
'unit': 'processing_unit',
'control_id': 0x03 ,
'offset': 0 ,
'data_len': 1 ,
'bit_mask': 1<<2,
'd_type': bool,
'doc':'0: frame rate must remain constant; 1: frame rate may be varied for AE purposes'
}
,
{
'display_name': 'Absolute Exposure Time',
'unit': 'processing_unit',
'control_id': 0x04 ,
'offset': 0 ,
'data_len': 4 ,
'bit_mask': 1<<3,
'd_type': int,
'doc': 'The `time` parameter should be provided in units of 0.0001 seconds (e.g., use the value 100 \
for a 10ms exposure period). Auto exposure should be set to `manual` or `shutter_priority`\
before attempting to change this setting.'
}
]



cdef class Control:
    cdef uvc.uvc_device_handle_t *devh
    cdef bytes display_name,doc
    cdef int unit_id,control_id,offset,data_len,bit_mask
    cdef int _value,min_val,max_val,step,default,buffer_len,info_bit_mask
    cdef object d_type

    def __cinit__(self,display_name,unit,control_id,offset,data_len,bit_mask,d_type,doc):
        pass

    def __init__(self,display_name,unit,control_id,offset,data_len,bit_mask,d_type,doc):
        self.devh = NULL
        self.display_name = display_name
        self.unit_id = {'processing_unit':3,'input_terminal':1}[unit]
        self.control_id = control_id
        self.offset = offset
        self.data_len = data_len
        self.bit_mask = bit_mask
        self.d_type = d_type
        self.doc = doc


    cdef init_vars(self):
        self.buffer_len = uvc.uvc_get_ctrl_len(self.devh,self.unit_id, self.control_id)
        if self.buffer_len < 1:
            raise Exception("Error: %s"%uvc_error_codes[self.buffer_len])

        print self.buffer_len

        self.min_val = self._uvc_get(uvc.UVC_GET_MIN)
        self.max_val = self._uvc_get(uvc.UVC_GET_MAX)
        self.step = self._uvc_get(uvc.UVC_GET_RES)
        self.default = self._uvc_get(uvc.UVC_GET_DEF)
        self._value = self._uvc_get(uvc.UVC_GET_CUR)
        self.info_bit_mask = self._uvc_get(uvc.UVC_GET_INFO)


    def print_info(self):
        print self.display_name
        print '\t value: %s'%self._value
        print '\t min; %s'%self.min_val
        print '\t max; %s'%self.max_val
        print '\t step; %s'%self.step

    cdef _uvc_get(self, req_code):
        cdef uvc.uint8_t data[12] #should be done dynamically
        cdef int ret,value
        ret =  uvc.uvc_get_ctrl(self.devh, self.unit_id, self.control_id,data,self.data_len, req_code)
        if ret >0: #== self.buffer_len
            if self.data_len == 1:
                return data[0]
            elif self.data_len ==2:
                return uvc.SW_TO_SHORT(data + self.offset)
            else:
                return uvc.DW_TO_INT(data + self.offset)
        else:
            raise Exception("Error: %s"%uvc_error_codes[ret])

    cdef _uvc_set(self, value):
        cdef uvc.uint8_t data[12] #should be done dynamically
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


