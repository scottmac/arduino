/* MD2 */

typedef struct {
	unsigned char state[48];
	unsigned char checksum[16];
	unsigned char buffer[16];
	char in_buffer;
} MD2_CTX;

static const unsigned char MD2_S[256] = {
	 41,  46,  67, 201, 162, 216, 124,   1,  61,  54,  84, 161, 236, 240,   6,  19,
	 98, 167,   5, 243, 192, 199, 115, 140, 152, 147,  43, 217, 188,  76, 130, 202,
	 30, 155,  87,  60, 253, 212, 224,  22, 103,  66, 111,  24, 138,  23, 229,  18,
	190,  78, 196, 214, 218, 158, 222,  73, 160, 251, 245, 142, 187,  47, 238, 122,
	169, 104, 121, 145,  21, 178,   7,  63, 148, 194,  16, 137,  11,  34,  95,  33,
	128, 127,  93, 154,  90, 144,  50,  39,  53,  62, 204, 231, 191, 247, 151,   3,
	255,  25,  48, 179,  72, 165, 181, 209, 215,  94, 146,  42, 172,  86, 170, 198,
	 79, 184,  56, 210, 150, 164, 125, 182, 118, 252, 107, 226, 156, 116,   4, 241,
	 69, 157, 112,  89, 100, 113, 135,  32, 134,  91, 207, 101, 230,  45, 168,   2,
	 27,  96,  37, 173, 174, 176, 185, 246,  28,  70,  97, 105,  52,  64, 126,  15,
	 85,  71, 163,  35, 221,  81, 175,  58, 195,  92, 249, 206, 186, 197, 234,  38,
	 44,  83,  13, 110, 133,  40, 132,   9, 211, 223, 205, 244,  65, 129,  77,  82,
	106, 220,  55, 200, 108, 193, 171, 250,  36, 225, 123,   8,  12, 189, 177,  74,
	120, 136, 149, 139, 227,  99, 232, 109, 233, 203, 213, 254,  59,   0,  29,  57,
	242, 239, 183,  14, 102,  88, 208, 228, 166, 119, 114, 248, 235, 117,  75,  10,
	 49,  68,  80, 180, 143, 237,  31,  26, 219, 153, 141,  51, 159,  17, 131,  20 };

void MD2Init(void *contextBuf)
{
	MD2_CTX *context = (MD2_CTX*)contextBuf;
	memset(context, 0, sizeof(MD2_CTX));
}

static void MD2_Transform(void *contextBuf, const unsigned char *block)
{
	MD2_CTX *context = (MD2_CTX*)contextBuf;
	unsigned char i,j,t = 0;

	for(i = 0; i < 16; i++) {
		context->state[16+i] = block[i];
		context->state[32+i] = (context->state[16+i] ^ context->state[i]);
	}

	for(i = 0; i < 18; i++) {
		for(j = 0; j < 48; j++) {
			t = context->state[j] = context->state[j] ^ MD2_S[t];
		}
		t += i;
	}

	/* Update checksum -- must be after transform to avoid fouling up last message block */
	t = context->checksum[15];
	for(i = 0; i < 16; i++) {
		t = context->checksum[i] ^= MD2_S[block[i] ^ t];
	}
}

void MD2Update(void *contextBuf, const unsigned char *buf, unsigned int len)
{
	MD2_CTX *context = (MD2_CTX*)contextBuf;
	const unsigned char *p = buf, *e = buf + len;

	if (context->in_buffer) {
		if (context->in_buffer + len < 16) {
			/* Not enough for block, just pass into buffer */
			memcpy(context->buffer + context->in_buffer, p, len);
			context->in_buffer += len;
			return;
		}
		/* Put buffered data together with inbound for a single block */
		memcpy(context->buffer + context->in_buffer, p, 16 - context->in_buffer);
		MD2_Transform(context, context->buffer);
		p += 16 - context->in_buffer;
		context->in_buffer = 0;
	}

	/* Process as many whole blocks as remain */
	while ((p + 16) <= e) {
		MD2_Transform(context, p);
		p += 16;
	}

	/* Copy remaining data to buffer */
	if (p < e) {
		memcpy(context->buffer, p, e - p);
		context->in_buffer = e - p;
	}
}

void MD2Final(unsigned char output[16], void *contextBuf)
{
	MD2_CTX *context = (MD2_CTX*)contextBuf;
	memset(context->buffer + context->in_buffer, 16 - context->in_buffer, 16 - context->in_buffer);
	MD2_Transform(context, context->buffer);
	MD2_Transform(context, context->checksum);

	memcpy(output, context->state, 16);
}

void make_digest(char *md5str, const unsigned char *digest, int len) /* {{{ */
{
	static const char hexits[17] = "0123456789abcdef";
	int i;

	for (i = 0; i < len; i++) {
		md5str[i * 2]       = hexits[digest[i] >> 4];
		md5str[(i * 2) + 1] = hexits[digest[i] &  0x0F];
	}
	md5str[len * 2] = '\0';
}

void do_md2(char *arg)
{
	char md2str[33];
	MD2_CTX context;
	unsigned char digest[16];
	
	md2str[0] = '\0';
	MD2Init(&context);
	MD2Update(&context, (unsigned char*)arg, strlen(arg));
	MD2Final(digest, &context);

	make_digest(md2str, digest, 16);
	Serial.println(md2str);
}

void setup() {
	Serial.begin(9600);
}

void loop() {
	do_md2("The quick brown fox jumps over the lazy dog");

	delay(1000);  
}
