//
//  DataUtil.m
//  r4ss
//
//  Created by teanet on 08.05.2023.
//

#import "DataUtil.h"

@import Foundation;

@implementation DataUtil

#define BLE_INPUT_BUFFSIZE 64
#define cStatus_len 128

struct BleDevSt {
	int      MiKettleID;
	bool     btopenreq;
	bool     btopen;
	bool     btauthoriz;
	bool     get_server;
	uint8_t  notifyData[BLE_INPUT_BUFFSIZE];
	int8_t   notifyDataLen;
	uint8_t  readData[BLE_INPUT_BUFFSIZE];
	int8_t   readDataLen;
	int8_t   readDataHandle;
	uint8_t  sendData[BLE_INPUT_BUFFSIZE];
	int8_t   sendDataLen;
	int8_t   sendDataHandle;
	uint8_t  DEV_TYP;
	char     REQ_NAME[16];
	char     RQC_NAME[16];
	char     DEV_NAME[16];
	char     tBLEAddr[16];
	char     sVer[12];
	uint32_t NumConn;
	uint32_t PassKey;
	uint8_t  LstCmd;
	uint8_t  r4scounter;
	uint8_t  r4sConnErr;
	uint8_t  r4sAuthCount;
	uint8_t  xbtauth;
	uint8_t  xshedcom;
	uint8_t  r4slpcom;
	uint8_t  r4sppcom;
	uint8_t  r4slppar1;
	uint8_t  r4slppar2;
	uint8_t  r4slppar3;
	uint8_t  r4slppar4;
	uint8_t  r4slppar5;
	uint8_t  r4slppar6;
	uint8_t  r4slppar7;
	uint8_t  r4slppar8;
	uint8_t  r4slpres;
	uint8_t  t_ppcon;
	uint16_t t_rspdel;
	uint8_t  t_rspcnt;
	uint8_t  f_Sync;
	char     cStatus[cStatus_len];
	int      iRssi;
	uint8_t  bState;
	uint8_t  bHeat;
	uint8_t  bLock;
	uint8_t  bProg;
	uint8_t  bModProg;
	uint8_t  bPHour;
	uint8_t  bPMin;
	uint8_t  bCHour;
	uint8_t  bCMin;
	uint8_t  bDHour;
	uint8_t  bDMin;
	uint8_t  bStNl;
	uint8_t  bStBl;
	uint8_t  bStBp;
	uint8_t  bCtemp;
	uint8_t  bHtemp;
	uint8_t  bAwarm;
	int8_t   bBlTime;
	uint8_t  RgbR;
	uint8_t  RgbG;
	uint8_t  RgbB;
	uint32_t bSEnergy;
	uint32_t bSTime;
	uint32_t bSCount;
	uint32_t bSHum;
	uint8_t  bCVol;
	uint8_t  bCVoll;
	uint32_t bS1Energy;
	uint8_t  bC1temp;
	uint8_t  bCStemp;
	uint8_t  bLtemp;
	uint8_t  bKeep;
	uint8_t  bEfficiency;

	char     cprevStatus[cStatus_len];
	int      iprevRssi;
	uint8_t  bprevState;
	uint8_t  bprevHeat;
	uint8_t  bprevLock;
	uint8_t  bprevProg;
	uint8_t  bprevModProg;
	uint8_t  bprevPHour;
	uint8_t  bprevPMin;
	uint8_t  bprevCHour;
	uint8_t  bprevCMin;
	uint8_t  bprevDHour;
	uint8_t  bprevDMin;
	uint8_t  bprevStNl;
	uint8_t  bprevStBl;
	uint8_t  bprevStBp;
	uint8_t  bprevCtemp;
	uint8_t  bprevHtemp;
	uint8_t  bprevAwarm;
	int8_t   bprevBlTime;
	uint8_t  PRgbR;
	uint8_t  PRgbG;
	uint8_t  PRgbB;
	uint32_t bprevSEnergy;
	uint32_t bprevSTime;
	uint32_t bprevSCount;
	uint32_t bprevSHum;
	uint8_t  bprevCVol;
	uint8_t  bprevCVoll;

};

static struct BleDevSt dev;

void cipherInit(uint8_t  *cin, uint8_t  *ctab, int keysize)
{
	if (cin == NULL || ctab == NULL || keysize == 0) return;
	int i;
	int j = 0;
	char a;
	char b;
	for (i = 0; i < 256; i++) ctab[i] = i;
	for (i = 0; i < 256; i++) {
		j += ctab[i] + cin[i%keysize];
		j = j & 0xff;
		a = ctab[i];
		b = ctab[j];
		ctab[j] = a;
		ctab[i] = b;
	}
}
void cipherCrypt(uint8_t  *cin, uint8_t  *cout, uint8_t  *ctab, int size)
{
	if (cin == NULL || cout == NULL || cout == NULL || size == 0) return;
	int i;
	int idx;
	int idx1 = 0;
	int idx2 = 0;
	char a;
	char b;
	for (i = 0; i < size; i++) {
		idx1++;
		idx1 = idx1 & 0xff;
		idx2 += ctab[idx1];
		idx2 = idx2 & 0xff;
		a = ctab[idx1];
		b = ctab[idx2];
		ctab[idx2] = a;
		ctab[idx1] = b;
		idx = ctab[idx1] + ctab[idx2];
		idx = idx & 0xff;
		cout[i] = cin[i] ^ ctab[idx];
	}
}

void mixA(uint8_t  *cin, uint8_t  *cout, int prid)
{
	if (cin == NULL || cout == NULL) return;
	cout[0] = cin[5];
	cout[1] = cin[3];
	cout[2] = cin[0];
	cout[3] = prid & 0xff;
	cout[4] = prid & 0xff;
	cout[5] = cin[1];
	cout[6] = cin[0];
	cout[7] = cin[4];
}

uint8_t r4sWrite(uint8_t cmd, uint8_t* data, size_t len)
{
	struct BleDevSt *ptr = &dev;
//	uint8_t  sendData[BLE_INPUT_BUFFSIZE];
	size_t sz = 4 + len; // 55, counter, cmd, AA
	ptr->sendData[0] = 0x55;
	ptr->sendData[1] = ptr->r4scounter;
	ptr->sendData[2] = cmd;
	ptr->sendData[sz - 1] = 0xAA;
	if (len > 0) {
		memcpy(&ptr->sendData[3], data, len);
	}
	ptr->sendDataLen = sz;
	return ptr->r4scounter++;
}

- (NSData *)data
{
	struct BleDevSt *ptr = &dev;
	uint8_t data[] = { 0, 0, 0, 0, 0, ptr->bDHour, ptr->bDMin, ptr->bAwarm};
	data[1] = 0;     	//mode
	data[2] = 150;		//temp
	data[3] = 0;		//shour
	data[4] = 15;		//smin
	r4sWrite(0x05, data, sizeof(data));

	return [NSData dataWithBytes:ptr->sendData length:ptr->sendDataLen];
}

void asd(int a)
{
	uint8_t binblemac [8] = { 0xF4,0xD4,0x88,0x6F,0x14,0xC2 };
//	uint8_t buff2[16];
	uint8_t xiv_char_data[12] = { 0x55,0x00,0xff,0xb6,0x2c,0x27,0xb3,0xb8,0xac,0x5a,0xef,0xaa};  //auth string
	int blenum = 0;
	int R4SNUM = 0;
	xiv_char_data[3] = xiv_char_data[3] + blenum;  //for each position number different auth id
	xiv_char_data[5] = xiv_char_data[5] + R4SNUM;  //for each gate number different auth id
												   //	if (macauth) {                                 // for each esp32 different auth id
	xiv_char_data[4] = binblemac [0];
	xiv_char_data[6] = binblemac [1];
	xiv_char_data[7] = binblemac [2];
	xiv_char_data[8] = binblemac [3];
	xiv_char_data[9] = binblemac [4];
	xiv_char_data[10] = binblemac [5];
	//	}
//	mixA(gl_profile_tab[blenum].remote_bda, buff1, ptr->MiKettleID);
//	cipherInit(buff1, bufftab, 8);
//	cipherCrypt(p_data->notify.value, buff2, bufftab, 12);
//	mixB(gl_profile_tab[blenum].remote_bda, buff1, ptr->MiKettleID);
//	cipherInit(buff1, bufftab, 8);
//	cipherCrypt(buff2, buff1, bufftab, 12);
//	if (!memcmp(xiv_char_data, buff1, 12)) {
//		buff2[0] = 0x92;
//		buff2[1] = 0xab;
//		buff2[2] = 0x54;
//		buff2[3] = 0xfa;
//		cipherInit(xiv_char_data, bufftab, 12);
//		cipherCrypt(buff2, buff1, bufftab, 4);
//		if (fdebug) {
//			ESP_LOGI(AP_TAG, "Write_auth_xi_ack %d:", blenum1);
//			esp_log_buffer_hex(AP_TAG, buff1, 4);
//		}
//	}
}

@end
