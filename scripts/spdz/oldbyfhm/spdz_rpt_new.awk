# ��һ��for subfile
# �ڶ���for sumfile

BEGIN {
FS=";"
}

/^50/ { 
	fee[0]  += $6+$8+$9+$10+$11+$12+$13+$14+$15+$16+$17
	fee[1]  += $6
	fee[2]  += $8+$9+$10+$11+$12+$13+$14+$15+$16+$17
	fee[3]  += $8
	fee[4]  += $9
	fee[5]  += $10
	fee[6]  += $11
	fee[7]  += $12
	fee[8]  += $13
	fee[9]  += $14
	fee[10] += $15
	fee[11] += $16
	fee[12] += $17
}

END {
	#subfile tail
	for(i=0; i<13; i+=1) {
		printf("%014.0f", fee[i]);
	}
	printf("%014.0f%014.0f%40s\r\n", 0, fee[12], " ")
	
	# sumfile tail:Ӧ������Ϣ�Ѻϼ�[14]|������ͨ�ŷѺϼ�[14]|ʵ�ʽ�����ϼ�|�����ֶ�1[30]
	printf("%014.0f%014.0f%014.0f%30s\r\n", fee[12], 0, fee[12], " ")
}	