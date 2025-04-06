import os from "node:os"

function getLocalIPAddress() {
  const networkInterfaces = os.networkInterfaces();

  for (const interfaceName in networkInterfaces) {
    const interfaceInfo = networkInterfaces[interfaceName];
    for (const net of interfaceInfo) {
       if (
         net.family === "IPv4" &&
         !net.internal &&
         (interfaceName === "Ethernet 2" || interfaceName === "Wi-Fi")
       ) {
         {
           // console.log(net.address);
           return net.address;
         }
       }
    }
  }

  return "Unable to determine IP address";
}
export default getLocalIPAddress()