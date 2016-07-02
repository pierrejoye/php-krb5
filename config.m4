AC_MSG_CHECKING([PHP version])
tmp_version=$PHP_VERSION
if test -z "$tmp_version"; then
  if test -z "$PHP_CONFIG"; then
    AC_MSG_ERROR([php-config not found])
  fi
  php_version=`$PHP_CONFIG --version 2> /dev/null | head -n 1 | sed -e 's#\([0-9]\.[0-9]*\.[0-9]*\)\(.*\)#\1#'`
else
  php_version=`echo "$PHP_VERSION" | sed -e 's#\([0-9]\.[0-9]*\.[0-9]*\)\(.*\)#\1#'`
fi

if test -z "$php_version"; then
  AC_MSG_ERROR([failed to detect PHP version, please report])
else
  AC_MSG_RESULT([$php_version])
fi

ac_IFS=$IFS
IFS="."
set $php_version
IFS=$ac_IFS
hs_php_version=`expr [$]1 \* 1000000 + [$]2 \* 1000 + [$]3`

PHP_ARG_WITH(krb5, for kerberos support,
 [  --with-krb5             Include generic kerberos5/GSSAPI support]
 )

PHP_ARG_WITH(krb5config, path to krb5config tool,
 [  --with-krb5config       Path to krb5config tool],
 no, no
 )

PHP_ARG_WITH(krb5kadm, for kerberos KADM5 support,
 [  --with-krb5kadm[=S]      Include KADM5 Kerberos Administration Support - MIT only],
 no, no
 )

if test "$PHP_KRB5" != "no" -o "$PHP_KRB5KADM" != "no"; then


	if test "$PHP_KRB5CONFIG" == "no"; then
		PHP_KRB5CONFIG=`which krb5-config`
	fi

	AC_MSG_CHECKING([whether we have krb5config])

	if test -x $PHP_KRB5CONFIG; then
		AC_MSG_RESULT($PHP_KRB5CONFIG)
	else
		AC_MSG_ERROR([no])
		exit
	fi



	if test "$PHP_KRB5KADM" != "no"; then
		KRB5_LDFLAGS=`$PHP_KRB5CONFIG --libs krb5 gssapi kadm-client`
		KRB5_CFLAGS=`$PHP_KRB5CONFIG --cflags krb5 gssapi kadm-client`
	else
		KRB5_LDFLAGS=`$PHP_KRB5CONFIG --libs krb5 gssapi`
		KRB5_CFLAGS=`$PHP_KRB5CONFIG --cflags krb5 gssapi`
	fi

	AC_MSG_CHECKING([for required linker flags])
	AC_MSG_RESULT($KRB5_LDFLAGS)

	AC_MSG_CHECKING([for required compiler flags])
	AC_MSG_RESULT($KRB5_CFLAGS)

	KRB5_VERSION=`$PHP_KRB5CONFIG --version`

	AC_MSG_CHECKING([for kerberos library version])
	AC_MSG_RESULT($KRB5_VERSION)
	AC_DEFINE_UNQUOTED(KRB5_VERSION, ["$KRB5_VERSION"], [Kerberos library version])

	if test "$hs_php_version" -ge "7000000"; then
dnl	  	SOURCE_FILES="php7/krb5.c php7/negotiate_auth.c php7/gssapi.c"
	  	SOURCE_FILES="php7/krb5.c php7/negotiate_auth.c php7/gssapi.c"
	else
	  	SOURCE_FILES="php5/krb5.c php5/negotiate_auth.c php5/gssapi.c"
	fi

	if test "$PHP_KRB5KADM" != "no"; then
		SOURCE_FILES="${SOURCE_FILES} kadm.c kadm5_principal.c kadm5_policy.c kadm5_tldata.c"
		AC_DEFINE(HAVE_KADM5, [], [Enable KADM5 support])
	fi

	CFLAGS="-Wall ${CFLAGS} ${KRB5_CFLAGS}"
	LDFLAGS="${LDFLAGS} ${KRB5_LDFLAGS}"
	PHP_SUBST(CFLAGS)
	PHP_SUBST(LDFLAGS)

	PHP_NEW_EXTENSION(krb5, $SOURCE_FILES, $ext_shared)
	PHP_INSTALL_HEADERS([ext/krb5], [php_krb5.h])
fi
