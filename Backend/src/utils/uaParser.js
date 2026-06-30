const parseUserAgent = (uaString = '') => {
  let browser = 'Unknown';
  let operatingSystem = 'Unknown';
  let deviceName = 'Desktop';

  const ua = uaString.toLowerCase();

  // Parse Operating System
  if (ua.includes('windows phone')) operatingSystem = 'Windows Phone';
  else if (ua.includes('win')) operatingSystem = 'Windows';
  else if (ua.includes('macintosh') || ua.includes('mac os x')) operatingSystem = 'macOS';
  else if (ua.includes('iphone') || ua.includes('ipad') || ua.includes('ipod')) operatingSystem = 'iOS';
  else if (ua.includes('android')) operatingSystem = 'Android';
  else if (ua.includes('linux')) operatingSystem = 'Linux';

  // Parse Browser
  if (ua.includes('opr/') || ua.includes('opera')) browser = 'Opera';
  else if (ua.includes('edg/') || ua.includes('edge')) browser = 'Edge';
  else if (ua.includes('chrome') && !ua.includes('chromium')) browser = 'Chrome';
  else if (ua.includes('safari') && !ua.includes('chrome')) browser = 'Safari';
  else if (ua.includes('firefox')) browser = 'Firefox';
  else if (ua.includes('msie') || ua.includes('trident')) browser = 'Internet Explorer';

  // Parse Device Type
  if (ua.includes('mobile') || ua.includes('iphone') || ua.includes('android')) {
    deviceName = 'Mobile';
  } else if (ua.includes('ipad') || ua.includes('tablet')) {
    deviceName = 'Tablet';
  }

  return { browser, operatingSystem, deviceName };
};

module.exports = { parseUserAgent };
