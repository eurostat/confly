data u1 (drop=COUNTRY YEAR QUARTER HHNUM hash_hex);
   COUNTRY = 'XX';
   YEAR = '2013';
   QUARTER = 'Q1';
   HHNUM = 123456;
   do seed = 1 to 5;
      s = seed;
      call ranuni(s, x);
	  hash_hex = put(md5(COUNTRY||YEAR||QUARTER||HHNUM||seed), hex32.);
	  hash_int = input(hash_hex, IB4.); /*  IB8. not accepted by RANUNI */
	  h = hash_int;
      call ranuni(h, y);
      output;
   end;
/*   COUNTRY = 'YY';
   YEAR = '2014';
   QUARTER = 'Q2';
   HHNUM = 654321;*/
   do seed = 5 to 1 by -1;
	  s = seed;
      call ranuni(s, x);
	  hash_hex = put(md5(COUNTRY||YEAR||QUARTER||HHNUM||seed), hex32.);
	  hash_int = input(hash_hex, IB4.); /*  IB8. not accepted by RANUNI */
	  h = hash_int;
      call ranuni(h, y);
      output;
   end;
run;

proc print label;
   label seed = 'seed input' s = 'seed output' hash_int = 'hash input' h = 'hash output' x = 'rkey(seed)' y = 'rkey(hash)';
run;