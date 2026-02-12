"use client";

import { useState } from "react";
import Upload from "../components/Upload";
import Feed from "../components/Feed";

export default function Home() {
  const [feedKey, setFeedKey] = useState(0);

  const refreshFeed = () => {
    setFeedKey((prev) => prev + 1);
  };

  return (
    <main className="min-h-screen bg-white p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8 text-center">Photo Share</h1>

        <Upload onUploadSuccess={refreshFeed} />

        <div className="mt-8">
          <h2 className="text-xl font-semibold mb-4 text-gray-800">Recent Photos</h2>
          <Feed keyProp={feedKey} />
        </div>
      </div>
    </main>
  );
}
