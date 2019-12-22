import "jasmine";
import { ServerInfo } from './ServerInfo';

describe("Server Info", () => {
    it("should work", () => {
      let serverInfo = new ServerInfo();
        expect(serverInfo.getUrl()).toBe('/Pingpong');
    });
});