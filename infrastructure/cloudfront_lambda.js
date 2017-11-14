'use strict';
exports.handler = (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;
    
	headers['strict-transport-security'] = [{
		key:   'Strict-Transport-Security', 
		value: "max-age=63072000; includeSubdomains; preload"
	}];

	headers['x-content-type-options'] = [{
		key:   'X-Content-Type-Options',
		value: "nosniff"
	}];

    headers['x-frame-options'] = [{
		key:   'X-Frame-Options',
		value: "DENY"
	}];

	headers['x-xss-protection'] = [{
		key: "X-XSS-Protection",
		value: "1; mode=block"
	}];
	headers['referrer-policy'] = [{
		key: "Referrer-Policy",
		value: "same-origin"
	}];
    
    // Pinned Keys: Let's Encrypt X3, DST Root CA X3
    headers['public-key-pins'] = [{
	key: 'Public-Key-Pins',
	value: 'pin-sha256="ylh1dur9y6kja30rran7jknbqg/uetlmkbgff2fuihg="; pin-sha256="vjs8r4z+80wjncr1ykepwqbosiri63wswxhimn+ewys="; max-age=1296001; includeSubDomains'
    }];

    callback(null, response);
};
