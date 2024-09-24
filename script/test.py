# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      sakamoto
#
# Created:     24/11/2017
# Copyright:   (c) sakamoto 2017
# Licence:     <your licence>
#-------------------------------------------------------------------------------
from serial import Serial
import random, time, subprocess
import Crypto.Cipher.AES as AES
import pickle

len_din = 128*2//8
len_dout = 128//8

#######################################################################################
######################################Commands#########################################
#######################################################################################
WRITE = 0x10
READ = 0x20
SWRST = 0x30
RUN = 0x40

ADDR_AES = 0x01
ADDR_TRG = 0x02
ADDR_PS  = 0x03

#######################################################################################
######################################Function#########################################
#######################################################################################
def sendCommand(command, addr, value, com):
    if addr == None:
        com.write([command])
    else:
        list_send_buf = []
        length = int(len(hex(value)[2:].rstrip("L")) / 2)
        for i in range(length + 1):
            list_send_buf.insert(0, (value >> i * 8) & 0xFF)
        for i in range(length, len_din):
            list_send_buf.insert(0, 0x00)
        list_send_buf.reverse()
        list_send_buf.insert(0, addr)
        list_send_buf.insert(0, command)
        com.write(list_send_buf)

def getResult(addr, com):
    com.write([READ, addr])
    str = com.read(len_dout).hex()
    return int(str, 16)

def print_wrong_byte(res, ans):
    res = res.to_bytes(16, 'big')
    ans = ans.to_bytes(16, 'big')
    
    for i in range(16):
        if res[i] != ans[i]:
            print(f'{i}, ', end='')
    print('')

def main():
    random.seed(0)
    key = 0x000102030405060708090a0b0c0d0e0f
    # key = 0x2b7e151628aed2a6abf7158809cf4f3c
    aes = AES.new(key.to_bytes(16, 'big'), AES.MODE_ECB)
    fault_cnt = 0
    list_correct_ctxt = []
    list_fpga_ctxt = []
    with Serial(port="COM6",baudrate=115200,bytesize=8, parity="N", stopbits=1, timeout=3, xonxoff=0, rtscts=0, writeTimeout=3, dsrdtr=None) as com:
            for loop in range(1000):

                # print('\nLoop: %d' %loop)

                ptxt = random.randint(0, 2**128-1)
                                
                #入力
                sendCommand(WRITE, ADDR_AES, (key << 128) + ptxt, com)
                #トリガ
                sendCommand(WRITE, ADDR_TRG, 0xa0, com)
                #位相
                # sendCommand(WRITE, ADDR_PS, 0x00, com)
                # #RUN
                sendCommand(RUN, None, None, com)
                
                #出力
                res = getResult(0x00, com)
                ans = aes.encrypt(ptxt.to_bytes(16, 'big'))
                ans = int.from_bytes(ans, 'big')
                list_correct_ctxt.append(ans)
                list_fpga_ctxt.append(res)

                if res != ans:
                    fault_cnt += 1
                    print(hex(res))
                    print(hex(ans))
                    print('wrong result')
                    print_wrong_byte(res, ans)
                    # exit()
            print(fault_cnt)
            
    with open(r'C:\Users\seedtyps\Desktop\correct_ctxt.pkl', 'wb') as f:
        pickle.dump(list_correct_ctxt, f)
    with open(r'C:\Users\seedtyps\Desktop\result_ctxt.pkl', 'wb') as f:
        pickle.dump(list_fpga_ctxt, f)

if __name__ == '__main__':
    start = time.time()
    main()
    process_time = time.time() - start
    print(process_time)